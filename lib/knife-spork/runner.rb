require 'app_conf'
require 'json'

require 'chef/cookbook_loader'
require 'chef/knife/core/object_loader'
require 'knife-spork/plugins'

module KnifeSpork
  module Runner
    module ClassMethods; end

    module InstanceMethods
      def spork_config
        return @spork_config unless @spork_config.nil?

        @spork_config = AppConf.new
        load_paths = [ File.expand_path('config/spork-config.yml'), '/etc/spork-config.yml', File.expand_path('~/.chef/spork-config.yml') ]
        load_paths.each do |load_path|
          if File.exists?(load_path)
            @spork_config.load(load_path)
            break
          end
        end

        @spork_config
      end

      def run_plugins(hook)
        cookbooks = [ @cookbooks || @cookbook ].flatten.compact.collect{|cookbook| cookbook.is_a?(::Chef::CookbookVersion) ? cookbook : load_cookbook(cookbook)}.sort{|a,b| a.name.to_s <=> b.name.to_s}
        environments = [ @environments || @environment ].flatten.compact.collect{|environment| environment.is_a?(::Chef::Environment) ? environment : load_environment(environment)}.sort{|a,b| a.name.to_s <=> b.name.to_s}

        KnifeSpork::Plugins.run(
          :config => spork_config,
          :hook => hook.to_sym,
          :cookbooks => cookbooks,
          :environments => environments,
          :ui => ui
        )
      end

      def load_environments_and_cookbook
        ensure_environment_provided!

        if @name_args.size == 2
          [ [@name_args[0]].flatten, @name_args[1] ]
        elsif @name_args.size == 1
          [ [default_environments].flatten, @name_args[0] ]
        end
      end

      def ensure_environment_provided!
        if default_environments.empty? && @name_args.size < 2
          ui.error('You must specify a cookbook name and an environment')
          exit(1)
        end
      end

      def default_environments
        [ spork_config.default_environment || spork_config.default_environments ].flatten.compact
      end

      def pretty_print_json(json)
        JSON.pretty_generate(json)
      end

      def valid_version?(version)
        version_keys = version.split('.')
        return false unless version_keys.size == 3 && version_keys.any?{ |k| begin Float(k); rescue false; else true; end }
        true
      end

      def validate_version!(version)
        if version && !valid_version?(version)
          ui.error("#{version} is not a valid version!")
          exit(1)
        end
      end

      def loader
        @loader ||= Chef::Knife::Core::ObjectLoader.new(::Chef::Environment, ui)
      end

      # It's not feasible to try and "guess" which cookbook path to use, so we will
      # always just use the first one in the path.
      def cookbook_path
        ensure_cookbook_path!
        [config[:cookbook_path] ||= ::Chef::Config.cookbook_path].flatten[0]
      end

      def all_cookbooks
        ::Chef::CookbookLoader.new(::Chef::Config.cookbook_path)
      end

      def load_cookbook(cookbook_name)
        return cookbook_name if cookbook_name.is_a?(::Chef::CookbookVersion)
        loader = ::Chef::CookbookLoader.new(cookbook_path)
        loader[cookbook_name]
      end

      def load_cookbooks(cookbook_names)
        cookbook_names = [cookbook_names].flatten
        cookbook_names.collect{ |cookbook_name| load_cookbook(cookbook_name) }
      end

      def load_environment(environment_name)
        loader.load_from('environments', "#{environment_name}.json")
      end

      def ensure_cookbook_path!
        if !config.has_key?(:cookbook_path)
          ui.fatal "No default cookbook_path; Specify with -o or fix your knife.rb."
          show_usage
          exit(1)
        end
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end
  end
end
