require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkEnvironmentAttributeUnset < Chef::Knife

    banner 'knife spork environment attribute unset ENVIRONMENT ATTRIBUTE'

    include KnifeSpork::Runner

    option  :no_upload,
            :long => '--no_upload',
            :description => 'whether or not to upload environment file'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a environment name and attribute")
        exit 1
      end

      environments = @name_args[0].split(",").map { |env| load_specified_environment_group(env) }.flatten

      if environments.length == 0
        ui.error("Environment group #{group} not found.")
        exit 2
      end

      run_plugins(:before_environment_attribute_unset)


      environments.each do |env|
        environment = load_environment_from_file(env)

        ui.msg "Modifying #{env}"
        unset(@name_args[1], environment)

        save_environment_changes_remote(env)
      end

      run_plugins(:after_environment_attribute_unset)
    end

    def unset(attributes, environment)
      levels = attributes.split(":")
      last_key = levels.pop

      last_hash = levels.inject(environment.default_attributes) do |h, k|
        h[k] unless h.nil?
      end

      unless last_hash.nil?
        last_hash.delete(last_key)
        environment.save unless config[:no_upload]
        ui.msg "Done modifying #{environment} at #{Time.now}"
      else
        ui.msg "Environment #{environment} not modified."
      end
    end

    def save_environment_changes_remote(environment)
      local_environment = load_environment_from_file(environment)
      remote_environment = load_remote_environment(environment)

      if local_environment.default_attributes != remote_environment.default_attributes
        save_environment_changes(environment, pretty_print_json(remote_environment.to_hash))
      end
    end
  end
end
