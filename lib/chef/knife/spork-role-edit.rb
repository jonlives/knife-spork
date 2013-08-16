require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkRoleEdit < Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork role edit ROLENAME'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @role = @name_args.first
      run_plugins(:before_roleedit)
      pre_role = load_role(@role)
      role_edit
      post_role = load_role(@role)
      @role_difference = role_diff(pre_role,post_role).to_s
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
