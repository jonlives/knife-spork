require 'chef/knife'
require 'knife-spork/runner'
require 'set'
require 'json'
require 'chef/mixin/deep_merge'

module KnifeSpork
  class SporkEnvironmentAttributeSet < Chef::Knife

    banner 'knife spork environment attribute set ENVIRONMENT ATTRIBUTE VALUE'

    include KnifeSpork::Runner

    option :no_upload,
           :long => '--no_upload',
           :description => 'whether or not to upload environment file'

    def run 
      self.config = Chef::Config.merge!(config)

      if @name_args.empty? 
        show_usage
        ui.error("You must specify a environment name, attribute and value")
        exit 1
      end

      environments = @name_args[0].split(",").map { |env| load_specified_environment_group(env) }.flatten
      key   = @name_args[1].to_s
      value = @name_args[2].to_s
      params = hashify(key, value)

      run_plugins(:before_environment_attribute_set)

      environments.each do |env|
        ui.msg "Modifying #{env}"
        environment = load_environment_from_file(env)

        environment.default_attributes = merge(environment.default_attributes, params)

        environment.save unless config[:no_upload]

        save_environment_changes_remote(environment)
      end

      run_plugins(:after_environment_attribute_set)
    end

    def save_environment_changes_remote(environment)
      local_environment = load_environment_from_file(environment)
      remote_environment = load_remote_environment(environment)

      if local_environment.default_attributes != remote_environment.default_attributes
        save_environment_changes(environment, pretty_print_json(remote_environment.to_hash))
        ui.msg "Done modifying #{environment} at #{Time.now}"
      else
        ui.msg "Environment #{environment} not modified."
      end
    end

    def merge(env1, env2)
      Chef::Mixin::DeepMerge.merge(env1, env2)
    end

    def hashify(string, value)
      {}.tap do |h|
        keys = string.split(':')
        keys.reduce(h) do |h,l|
          h[l] = (l == keys.last ? value : {})
        end
      end
    end
  end
end
