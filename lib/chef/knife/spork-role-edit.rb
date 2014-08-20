require 'chef/knife'

module KnifeSpork
  class SporkRoleEdit < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork role edit ROLENAME (options)'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_roleedit)
      pre_role = load_role(@object_name)
      role_edit
      post_role = load_role(@object_name)
      @object_difference = json_diff(pre_role,post_role).to_s
      run_plugins(:after_roleedit)
    end

    private
    def role_edit
      re = Chef::Knife::RoleEdit.new
      re.name_args = @name_args
      re.config[:editor] = config[:editor]
      re.run
    end
  end
end
