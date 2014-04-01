require 'chef/knife'
require 'chef/exceptions'
require 'knife-spork/runner'

module KnifeSpork
  class SporkEnvironmentCheck < Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork environment check ENVIRONMENT (options)'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify an environment name")
        exit 1
      end

      run_plugins(:before_environmentcheck)
      check_environment
      run_plugins(:after_environmentcheck)

      ui.msg 'Everything looks good!'
    end

    private

    def check_environment
      env = @name_args.first
      environment = load_environment_from_file(env)
      cookbook_versions = environment.cookbook_versions

      cookbook_versions.each do |cookbook, version_constraint|
        vc = Chef::VersionConstraint.new(version_constraint)
        check_cookbook_uploaded(cookbook, vc.version)
      end
    end

    def check_cookbook_uploaded(cookbook_name, version)
      environment = config[:environment]
      api_endpoint = environment ? "environments/#{environment}/cookbooks/#{cookbook_name}/#{version}" : "cookbooks/#{cookbook_name}/#{version}"

      begin
        cookbooks = rest.get_rest(api_endpoint)
      rescue Net::HTTPServerException => e
        ui.error "#{cookbook_name}@#{version} does not exist on Chef Server! Upload the cookbook first by running:\n\n\tknife spork upload #{cookbook_name}\n\n"
        exit(1)
      end
    end
  end
end
