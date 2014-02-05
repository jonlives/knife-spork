require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkEnvironmentCreate < Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork environment create ENVIRONMENT (options)'

    option :description,
           :short => "-d DESC",
           :long => "--description DESC",
           :description => "The environment description"

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a environment name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_environmentcreate)
      pre_environment = {}
      environment_create
      post_environment = load_environment(@object_name)
      @object_difference = json_diff(pre_environment,post_environment).to_s
      run_plugins(:after_environmentcreate)
    end

    private
    def environment_create
      rc = Chef::Knife::EnvironmentCreate.new
      rc.name_args = @name_args
      rc.config[:editor] = config[:editor]
      rc.config[:description] = config[:description]
      rc.run
    end
  end
end
