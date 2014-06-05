require 'chef/knife'

module KnifeSpork
  class SporkUpload < Chef::Knife

    deps do
      require 'chef/exceptions'
      require 'chef/cookbook_loader'
      require 'chef/cookbook_uploader'
      require 'knife-spork/runner'
      require 'socket'
    end

    CHECKSUM = 'checksum'
    MATCH_CHECKSUM = /[0-9a-f]{32,}/

    banner 'knife spork upload [COOKBOOKS...] (options)'

    option :cookbook_path,
      :short => '-o PATH:PATH',
      :long => '--cookbook-path PATH:PATH',
      :description => 'A colon-separated path to look for cookbooks in',
      :proc => lambda { |o| o.split(':') }

    option :freeze,
      :long => '--freeze',
      :description => 'Freeze this version of the cookbook so that it cannot be overwritten',
      :boolean => true

    option :depends,
      :short => '-D',
      :long => '--include-dependencies',
      :description => 'Also upload cookbook dependencies'

    if defined?(::Berkshelf)
      option :berksfile,
        :short => '-b',
        :long => 'berksfile',
        :description => 'Path to a Berksfile to operate off of',
        :default => File.join(Dir.pwd, ::Berkshelf::DEFAULT_FILENAME)
    end

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)
      config[:cookbook_path] ||= Chef::Config[:cookbook_path]

      if @name_args.empty?
        show_usage
        ui.error("You must specify the --all flag or at least one cookbook name")
        exit 1
      end

      #First load so plugins etc know what to work with
      @cookbooks = load_cookbooks(name_args)
      include_dependencies if config[:depends]

      run_plugins(:before_upload)

      #Reload cookbook in case a VCS plugin found updates
      @cookbooks = load_cookbooks(name_args)
      include_dependencies if config[:depends]

      upload
      run_plugins(:after_upload)
    end

    private
    def include_dependencies
      @cookbooks.each do |cookbook|
        @cookbooks.concat(load_cookbooks(cookbook.metadata.dependencies.keys))
      end

      @cookbooks.uniq!
    end

    def upload
      # upload cookbooks in reverse so that dependencies are satisfied first
      @cookbooks.reverse.each do |cookbook|
        begin
          check_dependencies(cookbook)
          if name_args.include?(cookbook.name.to_s)
            uploader = Chef::CookbookUploader.new(cookbook, ::Chef::Config.cookbook_path)
            begin
              if uploader.respond_to?(:upload_cookbooks)
                # Chef >= 10.14.0
                uploader.upload_cookbooks
                ui.info "Freezing #{cookbook.name} at #{cookbook.version}..."
                cookbook.freeze_version
                uploader.upload_cookbooks
              else
                uploader.upload_cookbook
                ui.info "Freezing #{cookbook.name} at #{cookbook.version}..."
                cookbook.freeze_version
                uploader.upload_cookbook

              end
            rescue Chef::Exceptions::CookbookFrozen => msg
              ui.error "#{cookbook.name}@#{cookbook.version} is frozen. Please bump your version number before continuing!"
              exit(1)
            end
          end
        rescue Net::HTTPServerException => e
          if e.response.code == '409'
            ui.error "#{cookbook.name}@#{cookbook.version} is frozen. Please bump your version number before continuing!"
            exit(1)
          else
            raise
          end
        end
      end

      ui.msg "Successfully uploaded #{@cookbooks.collect{|c| "#{c.name}@#{c.version}"}.join(', ')}!"
    end

    # Ensures that all the cookbooks dependencies are either already on the server or being uploaded in this pass
    def check_dependencies(cookbook)
      cookbook.metadata.dependencies.each do |cookbook_name, version|
        unless server_side_cookbooks(cookbook_name, version)
          ui.error "#{cookbook.name} depends on #{cookbook_name} (#{version}), which is not currently being uploaded and cannot be found on the server!"
          exit(1)
        end
      end
    end

    def server_side_cookbooks(cookbook_name, version)
      if Chef::CookbookVersion.respond_to?(:list_all_versions)
        @server_side_cookbooks ||= Chef::CookbookVersion.list_all_versions
      else
        @server_side_cookbooks ||= Chef::CookbookVersion.list
      end

      hash = @server_side_cookbooks[cookbook_name]
      hash && hash['versions'] && hash['versions'].any?{ |v| Chef::VersionConstraint.new(version).include?(v['version']) }
    end
  end
end
