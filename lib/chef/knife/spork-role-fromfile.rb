require 'chef/knife'

module KnifeSpork
  class SporkRoleFromFile < Chef::Knife

    deps do
      require 'knife-spork/runner'
      require 'json'
      require 'chef/knife/role_from_file'
    end

    banner 'knife spork role from file FILENAME (options)'

    option :message,
           :short => '-m',
           :long => '--message git_message',
           :description => 'Git commit message if auto_push is enabled'

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
          @args = { :git_message => config[:message] } 
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
