require 'chef/knife'

module KnifeSpork
  class SporkEnvironmentCheck < Chef::Knife

    deps do
      require 'knife-spork/runner'
      require 'chef/exceptions'
    end

    banner 'knife spork environment check ENVIRONMENT (options)'

    option :fatal,
           :short => '-f PATH:PATH',
           :long => '--fatal',
           :description => 'Quit on first invalid constraint located'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      #First load so plugins etc know what to work with
      @environments, _ = load_environments_and_cookbook

      run_plugins(:before_environmentcheck)

      #Reload cookbook and env in case a VCS plugin found updates
      @environments, _ = load_environments_and_cookbook

      check_environment
      run_plugins(:after_environmentcheck)
    end

    private

    def check_environment
      @environments.flatten.each do |e|
        environment = load_environment_from_file(e)
        cookbook_versions = environment.cookbook_versions

        cookbook_versions.each do |cookbook, version_constraint|
          vc = Chef::VersionConstraint.new(version_constraint)
          check_cookbook_uploaded(cookbook, vc.version)
        end
        ui.msg "#{e} looks good"
      end
    end

    def check_cookbook_uploaded(cookbook_name, version)
      environment = config[:environment]
      api_endpoint = environment ? "environments/#{environment}/cookbooks/#{cookbook_name}" : "cookbooks/#{cookbook_name}"

      begin
        cookbook = rest.get_rest(api_endpoint)
        results = cookbook[cookbook_name]['versions'].any? do |cv|
          cv['version'] == version.to_s
        end

        unless results
          fail_and_exit(cookbook_name, version)
        end
      rescue Net::HTTPServerException
        fail_and_exit(cookbook_name, version)
      end
    end

    def fail_and_exit(cookbook_name, version)
      ui.error "#{cookbook_name}@#{version} does not exist on Chef Server! Upload the cookbook first by running:\n\n\tknife spork upload #{cookbook_name}\n\n"
      if config[:fatal]
        exit(1)
      end
    end
  end
end
