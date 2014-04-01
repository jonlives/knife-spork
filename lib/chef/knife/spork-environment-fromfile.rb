require 'chef/knife'
require 'knife-spork/runner'
require 'json'

module KnifeSpork
  class SporkEnvironmentFromFile < Chef::Knife
    include KnifeSpork::Runner

    deps do
      require 'chef/knife/environment_from_file'
    end

    banner 'knife spork environment from file FILENAME (options)'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a environment name")
        exit 1
      end

      @name_args.each do |arg|
          @object_name = arg.split("/").last
          run_plugins(:before_environmentfromfile)
          pre_environment = load_environment_from_file(@object_name.gsub(".json","").gsub(".rb",""))
          environment_from_file
          post_environment = load_environment(@object_name.gsub(".json","").gsub(".rb",""))
          @object_difference = json_diff(pre_environment,post_environment).to_s
          run_plugins(:after_environmentfromfile)
      end
    end

    private
    def environment_from_file
      rff = Chef::Knife::EnvironmentFromFile.new
      rff.name_args = @name_args
      rff.run
    end
  end
end
