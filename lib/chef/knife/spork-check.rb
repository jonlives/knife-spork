require 'chef/knife'

module KnifeSpork
  class SporkCheck < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork check COOKBOOK (options)'

    option :all,
      :short => '--a',
      :long => '--all',
      :description => 'Show all uploaded versions of the cookbook'

    option :fail,
      :long => "--fail",
      :description => "If the check fails exit with non-zero exit code"

    option :cookbook_path,
      :short => '-o PATH:PATH',
      :long => '--cookbook-path PATH:PATH',
      :description => 'A colon-separated path to look for cookbooks in',
      :proc => lambda { |o| o.split(':') }

    option :berksfile,
      :short => '-b',
      :long => 'berksfile',
      :description => 'Path to a Berksfile to operate off of',
      :default => nil,
      :proc => lambda { |o| o || File.join(Dir.pwd, ::Berkshelf::DEFAULT_FILENAME) }

    option :skip_dependencies,
      :short => '-s',
      :long => '--skip-dependencies',
      :description => 'Berksfile skips resolving source cookbook dependencies',
      :default => true

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if name_args.empty?
        ui.fatal 'You must specify a cookbook name!'
        show_usage
        exit(1)
      end

      # Temporary fix for #138 to allow Berkshelf functionality
      # to be bypassed until #85 has been completed and Berkshelf 3 support added
      unload_berkshelf_if_specified

      #First load so plugins etc know what to work with
      initial_load

      run_plugins(:before_check)

      #Reload cookbook in case a VCS plugin found updates
      initial_load

      check
      run_plugins(:after_check)
    end

    private
    def check
      ui.msg "Checking versions for cookbook #{@cookbook.name}..."
      ui.msg ""
      ui.msg "Local Version:"
      ui.msg "  #{local_version}"
      ui.msg ""
      ui.msg "Remote Versions: (* indicates frozen)"
      remote_versions.each do |remote_version|
        if frozen?(remote_version)
          ui.msg " *#{remote_version}"
        else
          ui.msg "  #{remote_version}"
        end
      end
      ui.msg ""

      remote_versions.each do |remote_version|
        if remote_version == local_version
          if frozen?(remote_version)
            message = "Your local version (#{local_version}) is frozen on the remote server. You'll need to bump before you can upload."
            message_autobump = "Your local version (#{local_version}) is frozen on the remote server. Autobumping so you can upload."
            if config[:fail]
              fail_and_exit("#{message}")
            else
              answer = nil
              unless config[:yes]
                ui.warn("#{message}")
                answer = ui.ask("Would you like to perform a patch-level bump on the #{@cookbook.name} cookbook now? (Y/N)")
              else
                ui.warn message_autobump
              end
              if config[:yes] or answer == "Y" or answer == "y"
                bump = SporkBump.new
                bump.name_args = [@cookbook.name,"patch"]
                bump.run
              else
                ui.info "Skipping bump..."
              end
            end
          else
            message =  "The version #{local_version} exists on the server and is not frozen. Uploading will overwrite!"
            config[:fail] ? fail_and_exit("#{message}") : ui.error("#{message}")
          end

          return
        end
      end

      ui.msg 'Everything looks good!'
    end

    def initial_load
      begin
        @cookbook = load_cookbook(name_args.first)
      rescue Chef::Exceptions::CookbookNotFoundInRepo => e
        ui.error "#{name_args.first} does not exist locally in your cookbook path(s), Exiting."
        exit(1)
      end
    end

    def local_version
      @cookbook.version
    end

    def remote_versions
      @remote_versions ||= begin
        environment = config[:environment]
        api_endpoint = environment ? "environments/#{environment}/cookbooks/#{@cookbook.name}" : "cookbooks/#{@cookbook.name}"
        cookbooks = rest.get_rest(api_endpoint)

        versions = cookbooks[@cookbook.name.to_s]['versions']
        (config[:all] ? versions : versions[0..4]).collect{|v| v['version']}
      rescue Net::HTTPServerException => e
        ui.info "#{@cookbook.name} does not yet exist on the Chef Server!"
        return []
      end
    end

    def frozen?(version)
      @versions_cache ||= {}

      @versions_cache[version.to_sym] ||= begin
        environment = config[:environment]
        api_endpoint = environment ? "environments/#{environment}/cookbooks/#{@cookbook.name}" : "cookbooks/#{@cookbook.name}/#{version}"
        rest.get_rest(api_endpoint).to_hash['frozen?']
      end
    end

    def fail_and_exit(message, options={})
     	ui.fatal message
     	show_usage if options[:show_usage]
     	exit 1
    end
  end
end
