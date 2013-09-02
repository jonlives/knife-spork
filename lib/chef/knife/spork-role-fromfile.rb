require 'chef/knife'
require 'knife-spork/runner'
require 'json'

module KnifeSpork
  class SporkRoleFromFile < Chef::Knife
    include KnifeSpork::Runner

    deps do
      require 'chef/knife/role_from_file'
    end

    banner 'knife spork role from file FILENAME'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @name_args.each do |arg|
          @object_name = arg
          run_plugins(:before_rolefromfile)
          pre_role = load_role(@object_name.gsub(".json",""))
          role_from_file
          post_role = load_role(@object_name.gsub(".json",""))
          @object_difference = json_diff(pre_role,post_role).to_s
          run_plugins(:after_rolefromfile)
      end
    end

    private
    def role_from_file
      rff = Chef::Knife::RoleFromFile.new
      rff.name_args = @name_args
      rff.run
    end
  end
end
