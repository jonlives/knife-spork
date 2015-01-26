require 'chef/knife'

module KnifeSpork
  class SporkRoleFromFile < Chef::Knife

    deps do
      require 'knife-spork/runner'
      require 'json'
      require 'chef/knife/role_from_file'
    end

    banner 'knife spork role from file FILENAME (options)'

    option :match_filename,
        :long => '--match-filename',
        :short => '-f',
        :description => 'Ensure that the filename matches the name specified in the role (true|false).',
        :boolean => true,
        :default => false

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a role name")
        exit 1
      end

      @name_args.each do |arg|
          @object_name = arg.split("/").last
          run_plugins(:before_rolefromfile)
          begin
            pre_role = load_role(@object_name.gsub(".json","").gsub(".rb",""))
          rescue Net::HTTPServerException => e
            pre_role = {}
          end
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
      if (config[:match_filename] || spork_config[:role_match_file_name])
        ## Check if file names match role names 
        @name_args.each do |arg|
            file_name = arg.split("/").last
            role = rff.loader.load_from("roles", file_name)
            file_name = file_name.gsub(".json","").gsub(".rb", "")
            if file_name != role.name
                ui.error("Role name in file #{role.name} does not match file name #{file_name}")
                exit 1
            end
        end
      end
      rff.run
    end
  end
end
