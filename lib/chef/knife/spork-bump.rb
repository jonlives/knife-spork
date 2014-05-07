require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkBump < Chef::Knife
    include KnifeSpork::Runner

    TYPE_INDEX = { :major => 0, :minor => 1, :patch => 2, :manual => 3 }.freeze

    option :cookbook_path,
           :short => '-o PATH:PATH',
           :long => '--cookbook-path PATH:PATH',
           :description => 'A colon-separated path to look for cookbooks in',
           :proc => lambda { |o| o.split(':') }

    option :bump_comment,
           :long => '--bump_comment',
           :description => 'Bump will prompt for a Change comment, which will be appended to CHANGELOG.md along with the new version # and username',
           :default => nil

    if defined?(::Berkshelf)
      option :berksfile,
        :short => '-b',
        :long => 'berksfile',
        :description => 'Path to a Berksfile to operate off of',
        :default => File.join(Dir.pwd, ::Berkshelf::DEFAULT_FILENAME)

      option :skip_dependencies,
        :short => '-s',
        :long => '--skip-dependencies',
        :description => 'Berksfile skips resolving source cookbook dependencies',
        :default => true
    end

    banner 'knife spork bump COOKBOOK [major|minor|patch|manual]'

    def run
      self.config = Chef::Config.merge!(config)
      config[:cookbook_path] ||= Chef::Config[:cookbook_path]

      if @name_args.empty?
        show_usage
        ui.error("You must specify at least a cookbook name")
        exit 1
      end

      #First load so plugins etc know what to work with
      @cookbook = load_cookbook(name_args.first)

      run_plugins(:before_bump)

      #Reload cookbook in case a VCS plugin found updates
      @cookbook = load_cookbook(name_args.first)
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

      if config[:bump_comment]
        changelog_file =  "#{@cookbook.root_dir}/CHANGELOG.md"
        ui.info "Enter Change Log comment, then press Ctrl-D:  "
        change_comment = $stdin.read
        File.open(changelog_file, 'a') { |cl|
          cl.write("\n#{new_version}\n")
          cl.write("---------\n")
          cl.write("#{ENV['USER']} - #{change_comment}\n")
        }
      end
         
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
