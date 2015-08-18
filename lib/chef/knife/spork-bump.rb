require 'chef/knife'

module KnifeSpork
  class SporkBump < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    TYPE_INDEX = { :major => 0, :minor => 1, :patch => 2, :manual => 3 }.freeze

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

    banner 'knife spork bump COOKBOOK [major|minor|patch|manual]'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)
      config[:cookbook_path] ||= Chef::Config[:cookbook_path]

      cookbook_name = ""

      if @name_args.empty? && File.exists?("#{Dir.pwd}/metadata.rb")
        cookbook_name = File.read("#{Dir.pwd}/metadata.rb").split("\n").select{|l|l.start_with?("name")}.first.split.last.gsub("\"","").gsub("'","")
        ui.info "Cookbook name omitted, but metadata.rb for cookbook #{cookbook_name} found - bumping that."
      elsif @name_args.empty?
        show_usage
        ui.error("You must specify at least a cookbook name")
        exit 1
      else
        cookbook_name = name_args.first
      end

      # Temporary fix for #138 to allow Berkshelf functionality
      # to be bypassed until #85 has been completed and Berkshelf 3 support added
      unload_berkshelf_if_specified

      #First load so plugins etc know what to work with
      @cookbook = load_cookbook(cookbook_name)

      run_plugins(:before_bump)

      #Reload cookbook in case a VCS plugin found updates
      @cookbook = load_cookbook(cookbook_name)
      bump
      run_plugins(:after_bump)
    end

    private

    def bump
      old_version = @cookbook.version

      if bump_type == 3
        # manual bump
        version_array = manual_bump_version.split('.')
      else
        # major, minor, or patch bump
        version_array = old_version.split('.').collect{ |i| i.to_i }
        version_array[bump_type] += 1
        ((bump_type+1)..2).each{ |i| version_array[i] = 0 } # reset all lower version numbers to 0
      end

      new_version = version_array.join('.')

      metadata_file = "#{@cookbook.root_dir}/metadata.rb"
      new_contents = File.read(metadata_file).gsub(/(version\s+['"])[0-9\.]+(['"])/, "\\1#{new_version}\\2")
      File.open(metadata_file, 'w'){ |f| f.write(new_contents) }

      ui.info "Successfully bumped #{@cookbook.name} to v#{new_version}!"
    end

    def bump_type
      TYPE_INDEX[(name_args[1] || 'patch').to_sym]
    end

    def manual_bump_version
      version = name_args.last
      validate_version!(version)
      version
    end
  end
end
