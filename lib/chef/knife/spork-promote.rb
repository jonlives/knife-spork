require 'chef/knife'
require 'chef/exceptions'
require 'knife-spork/runner'

begin
  require 'berkshelf'
rescue LoadError; end

module KnifeSpork
  class SporkPromote < Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork promote ENVIRONMENT COOKBOOK (options)'

    option :version,
      :short => '-v',
      :long  => '--version VERSION',
      :description => 'Set the environment\'s version constraint to the specified version',
      :default => nil

    option :remote,
      :long  => '--remote',
      :description => 'Save the environment to the chef server in addition to the local JSON file',
      :default => nil

    if defined?(::Berkshelf)
      option :berksfile,
        :short => '-b',
        :long => 'berksfile',
        :description => 'Path to a Berksfile to operate off of',
        :default => File.join(Dir.pwd, ::Berkshelf::DEFAULT_FILENAME)
    end

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify the cookbook and environment to promote to")
        exit 1
      end

      #First load so plugins etc know what to work with
      @environments, @cookbook = load_environments_and_cookbook

      run_plugins(:before_promote)

      #Reload cookbook and env in case a VCS plugin found updates
      @environments, @cookbook = load_environments_and_cookbook

      check_cookbook_uploaded(@cookbook)

      @environments.each do |e|
        environment = load_environment(e)

        if @cookbook == 'all'
          ui.msg "Promoting ALL cookbooks to environment #{environment}"
          promote(environment, all_cookbooks)
        else
          promote(environment, @cookbook)
        end

        ui.msg "Saving changes to #{e}.json"

        new_environment_json = pretty_print_json(environment)
        save_environment_changes(e, new_environment_json)

        if config[:remote]
          ui.msg "Uploading #{environment.name}.json to Chef Server"
          save_environment_changes_remote(e)
          ui.info "Promotion complete at #{Time.now}!"
        else
          ui.info "Promotion complete. Don't forget to upload your changed #{environment.name}.json to Chef Server"
        end
      end
      run_plugins(:after_promote_local)
      if config[:remote]
        run_plugins(:after_promote_remote)
      end
    end

    def update_version_constraints(environment, cookbook, new_version)
      validate_version!(new_version)
      environment.cookbook_versions[cookbook] = "= #{new_version}"
    end

    def save_environment_changes_remote(environment)
      local_environment = load_environment(environment)
      remote_environment = load_remote_environment(environment)
      @environment_diffs ||= Hash.new
      @environment_diffs["#{environment}"] = environment_diff(local_environment, remote_environment)

      version_change_threshold = spork_config.version_change_threshold || 2
      env_constraints_diff = constraints_diff(@environment_diffs["#{environment}"]).select{|k,v| v > version_change_threshold}

      if env_constraints_diff.size !=0 then
        ui.warn 'You\'re about to promote a significant version number change to 1 or more cookbooks:'
        ui.warn @environment_diffs["#{environment}"].select{|k,v|env_constraints_diff.has_key?(k)}.collect{|k,v| "\t#{k}: #{v}"}.join("\n")

        begin
          ui.confirm('Are you sure you want to continue?')
        rescue SystemExit => e
          if e.status == 3
            ui.confirm("Would you like to reset your local #{environment}.json to match the remote server?")
            tmp = Chef::Environment.load(environment)
            save_environment_changes(environment, pretty_print_json(tmp))
            ui.info "#{environment}.json was reset"
          end

          raise
        end
      end

      if @environment_diffs["#{environment}"].size > 1
        ui.msg ""
        ui.warn "You're about to promote changes to several cookbooks at once:"
        ui.warn @environment_diffs["#{environment}"].collect{|k,v| "\t#{k}: #{v}"}.join("\n")

        begin
          ui.confirm('Are you sure you want to continue?')
        rescue SystemExit => e
          if e.status == 3
            ui.confirm("Would you like to reset your local #{environment}.json to match the remote server?")
            tmp = Chef::Environment.load(environment)
            save_environment_changes(environment, pretty_print_json(tmp))
            ui.info "#{environment}.json was reset"
          end

          raise
        end
      end

      local_environment.save
    end

    def save_environment_changes(environment, json)
      environments_path = spork_config[:environment_path] || cookbook_path.gsub('cookbooks', 'environments')
      environment_path = File.expand_path( File.join(environments_path, "#{environment}.json") )

      File.open(environment_path, 'w'){ |f| f.puts(json) }
    end

    def promote(environment, cookbook_names)
      cookbook_names = [cookbook_names].flatten

      cookbook_names.each do |cookbook_name|
        validate_version!(config[:version])
        version = config[:version] || load_cookbook(cookbook_name).version

        ui.msg "Adding version constraint #{cookbook_name} = #{version}"
        update_version_constraints(environment, cookbook_name, version)
      end
    end

    def check_cookbook_uploaded(cookbook_name)
      validate_version!(config[:version])
      version = config[:version] || load_cookbook(cookbook_name).version

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
