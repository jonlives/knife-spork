require 'chef/knife'

module KnifeSpork
  class SporkEnvironmentEdit < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork environment edit ENVIRONMENT (options)'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a environment name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_environmentedit)
      pre_environment = load_environment(@object_name)
      environment_edit
      post_environment = load_environment(@object_name)
      @object_difference = json_diff(pre_environment,post_environment).to_s
      run_plugins(:after_environmentedit)
    end

    private
    def environment_edit
      re = Chef::Knife::EnvironmentEdit.new
      re.name_args = @name_args
      re.config[:editor] = config[:editor]
      re.run
    end
  end
end
