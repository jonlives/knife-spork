require 'chef/knife'

module KnifeSpork
  class SporkRoleDelete < Chef::Knife

    deps do
      require 'knife-spork/runner'
      require 'chef/search/query'
    end

    banner 'knife spork role delete ROLENAME (options)'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_roledelete)

      if spork_config.role_safe_delete
        query = Chef::Search::Query.new
        nodes = query.search('node', "roles:#{@object_name}").first
        if nodes.size > 0
          ui.fatal("#{nodes.size} nodes have been found which still contain the role #{@object_name} in their runlists. Please remove this role from all runlists before deleting it.")
          exit(1)
        end
      end

      pre_role = load_role(@object_name)
      role_delete
      post_role = {}
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
