require 'chef/knife'

module KnifeSpork
  class SporkEnvironmentCheck < Chef::Knife

    deps do
      require 'knife-spork/runner'
      require 'chef/exceptions'
    end

    banner 'knife spork environment check ENVIRONMENT (options)'

    option :fatal,
           :short => '-f',
           :long => '--fatal',
           :description => 'Quit on first invalid constraint located'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      #First load so plugins etc know what to work with
      @environments = verify_and_load_environments

      run_plugins(:before_environmentcheck)

      #Reload cookbook and env in case a VCS plugin found updates
      @environments = verify_and_load_environments

      check_environments
      run_plugins(:after_environmentcheck)
    end

    private

    def check_environments
      @environments.each do |e|
        env_status = true
        ui.info "\nChecking constraints for environment: #{e}\n"
        environment = load_environment_from_file(e)
        cookbook_versions = environment.cookbook_versions

        cookbook_versions.each do |cookbook, version_constraint|
          vc = Chef::VersionConstraint.new(version_constraint)
          status = check_cookbook_uploaded(cookbook, vc.version)
          if !status
            fail_and_exit(cookbook, vc.version)
            env_status = status
          end
        end

        if env_status
          ui.msg "Environment #{e} looks good"
        else
          ui.fatal "Environment #{e} has constraints that point to non existent cookbook versions."
          exit 1
        end
      end
    end

    def check_cookbook_uploaded(cookbook_name, version)
      api_endpoint = "cookbooks/#{cookbook_name}"

      begin
        cookbook = rest.get_rest(api_endpoint)
        results = cookbook[cookbook_name]['versions'].any? do |cv|
          cv['version'] == version.to_s
        end

        if results
          return true
        else
          return false
        end
      rescue Net::HTTPServerException
        false
      end
    end

    def fail_and_exit(cookbook_name, version)
      message = "#{cookbook_name}@#{version} does not exist on Chef Server! Upload the cookbook first by running:\n\n\tknife spork upload #{cookbook_name}\n\n"
      if config[:fatal]
        ui.fatal message
        exit 1
      else
        ui.error message
      end
    end
  end
end
