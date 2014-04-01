require 'chef/knife'
require 'knife-spork/runner'
require 'json'

module KnifeSpork
  class SporkRoleFromFile < Chef::Knife
    include KnifeSpork::Runner

    deps do
      require 'chef/knife/role_from_file'
    end

    banner 'knife spork role from file FILENAME (options)'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @name_args.each do |arg|
          @object_name = arg.split("/").last
          run_plugins(:before_rolefromfile)
          pre_role = load_role_from_file(@object_name.gsub(".json","").gsub(".rb",""))
          role_from_file
          post_role = load_role(@object_name.gsub(".json","").gsub(".rb",""))
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
