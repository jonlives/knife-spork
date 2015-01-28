require 'chef/knife'

module KnifeSpork
  class SporkEnvironmentCreate < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork environment create ENVIRONMENT (options)'

    option :description,
           :short => "-d DESC",
           :long => "--description DESC",
           :description => "The environment description"

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a environment name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_environmentcreate)

      # Check if environment already exists
      begin
        check_environment = load_environment(@object_name)
        if check_environment
          ui.confirm("It looks like the environment #{@object_name} already exists. Are you sure you want to overwrite it")
        end
      rescue Net::HTTPServerException
      end


      pre_environment = {}
      environment_create
      post_environment = load_environment(@object_name)

      if spork_config[:save_environment_locally_on_create]
        ui.msg "Saving environment changes to #{@object_name}.json"
        save_environment_changes(@object_name, pretty_print_json(post_environment))
      end

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
