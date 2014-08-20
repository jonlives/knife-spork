require 'chef/knife'

module KnifeSpork
  class SporkRoleCreate < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork role create ROLE (options)'

    option :description,
           :short => "-d DESC",
           :long => "--description DESC",
           :description => "The role description"

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_rolecreate)
      pre_role = {}
      role_create
      post_role = load_role(@object_name)
      @object_difference = json_diff(pre_role,post_role).to_s
      run_plugins(:after_rolecreate)
    end

    private
    def role_create
      rc = Chef::Knife::RoleCreate.new
      rc.name_args = @name_args
      rc.config[:editor] = config[:editor]
      rc.config[:description] = config[:description]
      rc.run
    end
  end
end
