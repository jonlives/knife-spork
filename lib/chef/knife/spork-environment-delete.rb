module KnifeSpork
  class SporkEnvironmentDelete < Chef::Knife

    deps do
      require 'chef/knife'
      require 'knife-spork/runner'
    end

    banner 'knife spork environment delete ENVIRONMENT (options)'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a environment name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_environmentdelete)
      pre_environment = load_environment(@object_name)
      environment_delete
      post_environment = {}
      @object_difference = json_diff(pre_environment,post_environment).to_s
      run_plugins(:after_environmentdelete)
    end

    private
    def environment_delete
      rd = Chef::Knife::EnvironmentDelete.new
      rd.name_args = @name_args
      rd.run
    end
  end
end
