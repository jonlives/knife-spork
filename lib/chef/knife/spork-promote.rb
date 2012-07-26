require 'chef/knife'
require 'chef/exceptions'

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

    def run
      self.config = Chef::Config.merge!(config)
      @environments, @cookbook = load_environments_and_cookbook

      run_plugins(:before_promote)

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
          ui.msg "Uploading #{environment.name} to Chef Server"
          save_environment_changes_remote(e)
          ui.info 'Promotion complete!'
        else
          ui.info "Promotion complete. Don't forget to upload your changed #{environment.name} to Chef Server"
        end
      end

      run_plugins(:after_promote)
    end

    def update_version_constraints(environment, cookbook, new_version)
      validate_version!(new_version)
      environment.cookbook_versions[cookbook] = "= #{new_version}"
    end

    def save_environment_changes_remote(environment)
      local_environment = load_environment(environment)

      begin
        remote_environment = Chef::Environment.load(environment)
      rescue Net::HTTPServerException => e
        ui.error "Could not load #{environment} from Chef Server. You must upload the environment manually the first time."
        exit(1)
      end

      local_environment_versions = local_environment.to_hash['cookbook_versions']
      remote_environment_versions = remote_environment.to_hash['cookbook_versions']
      environment_diff = remote_environment_versions.diff(local_environment_versions)

      if environment_diff.size > 1
        ui.warn 'You\'re about to promote changes to several cookbooks:'
        ui.warn environment_diff.collect{|k,v| "\t#{k}: #{v}"}.join("\n")

        begin
          ui.confirm('Are you sure you want to continue?')
        rescue SystemExit => e
          if e.status == 3
            ui.confirm("Would you like to reset your local #{environment}.json to match the remote server?")
            tmp = Chef::Environment.load(environment)
            save_environment_chages(environment, pretty_print_json(tmp))
            ui.info "#{environment}.json was reset"
          end

          raise
        end
      end

      local_environment.save
    end

    def save_environment_changes(environment, json)
      environments_path = cookbook_path.gsub('cookbooks', 'environments')
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
        ui.error "#{cookbook_name}@#{version} does not exist on Chef Server! Upload the cookbook first by running:\n\n\tknife cookbook upload #{cookbook_name}\n\n"
        exit(1)
      end
    end
  end
end

class Hash
  def diff(other)
    self.keys.inject({}) do |memo, key|
      unless self[key] == other[key]
        memo[key] = "#{self[key]} changed to #{other[key]}"
      end
      memo
    end
  end
end
