require 'chef/knife'

module KnifeSpork
  class SporkDelete < Chef::Knife
    deps do
      require 'chef/exceptions'
      require 'knife-spork/runner'
      require 'socket'
    end

    ALL_NO_CONF = 'all_no_conf'.freeze
    ALL_CONF = 'all_conf'.freeze
    ONE_NO_CONF = 'one_no_conf'.freeze
    ONE_CONF = 'one_conf'.freeze

    banner 'knife spork delete [COOKBOOKS...] (options)'

    option :cookbook_path,
      :short => '-o PATH:PATH',
      :long => '--cookbook-path PATH:PATH',
      :description => 'A colon-separated path to look for cookbooks in',
      :proc => lambda { |o| o.split(':') }

    option :yes,
      :short => '-y',
      :long => '--yes',
      :description => 'Say yes to all prompts for confirmation'

    option :all,
      :short => '-a',
      :long => '--all',
      :description => 'Delete all versions of the specified cookbooks'


    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)
      config[:cookbook_path] ||= Chef::Config[:cookbook_path]

      if @name_args.empty?
        show_usage
        ui.error("You must specify the --all flag or at least one cookbook name")
        exit 1
      end

      delete
      @misc_output = @deleted_cookbook_string
      run_plugins(:after_delete)
    end

    private

    def printable_version_string(version)
      # The version variable might be a string or an array. The array might even be empty.
      # Based on what it is, we will return a string that says something like "versions 1, 2" or "version 1" or "ALL versions"
      # for more human-readable output.
      if (version.class == Array and version.size == 0) or version == "ALL"
        return "ALL versions"
      elsif version.class == Array
        if version.size > 1
          return "versions #{version.join(', ')}"
        else
          return "version #{version.join(', ')}"
        end
      else
        return "version #{version}"
      end
    end 

    def run_knife_command(cookbook_name, command, version = [])
      begin
        ui.warn("Deleting cookbook #{cookbook_name}...")
        case command
        when ALL_NO_CONF
          @knife.delete_all_without_confirmation
        when ALL_CONF
          @knife.delete_all_versions
        when ONE_NO_CONF
          @knife.delete_versions_without_confirmation(version)
        when ONE_CONF
          @knife.version = version
          @knife.delete_explicit_version
        end
        ui.msg("Successfully deleted cookbook #{cookbook_name} #{printable_version_string(version)} from the Chef server")
        true
      rescue SystemExit
        # The user said no at a confirmation prompt, just continue. But return false since we
        # didn't actually delete anything.
        false
      rescue Exception => e
        ui.error("Error deleting cookbook #{cookbook_name}: #{e}")
        false
      end
    end

    def delete
      @deleted_cookbooks = []
      name_args.each do |cookbook_name|
        @knife = Chef::Knife::CookbookDelete.new
        @knife.name_args = cookbook_name
        @knife.cookbook_name = cookbook_name
        if config[:all]
          @knife.config[:all] = true
          if config[:yes]
            @deleted_cookbooks.push([cookbook_name, "ALL"]) if run_knife_command(cookbook_name, ALL_NO_CONF)
          else
            @deleted_cookbooks.push([cookbook_name, "ALL"]) if run_knife_command(cookbook_name, ALL_CONF)
          end
        else
          begin
            versions_to_delete = @knife.ask_which_versions_to_delete
          rescue NoMethodError
            # Rescuing this means the output from knife itself already gets printed, no need to duplicate that.
            exit 1
          end
          if config[:yes]
            @deleted_cookbooks.push([cookbook_name, versions_to_delete]) if run_knife_command(cookbook_name, ONE_NO_CONF, versions_to_delete)
          else
            versions_to_delete.each do |version|
              @deleted_cookbooks.push([cookbook_name, version]) if run_knife_command(cookbook_name, ONE_CONF, version)
            end  
          end
        end
      end
      # This is the formatted string that the plugins will use to print.
      @deleted_cookbook_string = ""
      @deleted_cookbooks.each {|cookbook, version| @deleted_cookbook_string << "#{cookbook}: #{printable_version_string(version)}, " }
      @deleted_cookbook_string.chop!.chop! # Get rid of the trailing , chop chop!
      ui.msg("Cookbooks deleted from chef server: #{@deleted_cookbook_string}")
    end     
  end
end
