require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkRoleDelete < Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork role delete ROLENAME'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_roledelete)
      pre_role = load_role(@object_name)
      role_delete
      post_role = "{}"
      @object_difference = json_diff(pre_role,post_role).to_s
      run_plugins(:after_roledelete)
    end

    private
    def role_delete
      rd = Chef::Knife::RoleDelete.new
      rd.name_args = @name_args
      rd.run
    end
  end
end
