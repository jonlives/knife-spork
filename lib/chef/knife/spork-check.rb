#
# Author:: Jon Cowie (<jonlives@gmail.com>)
# Copyright:: Copyright (c) 2011 Jon Cowie
# License:: GPL


require 'app_conf'
require 'json'
require 'chef/knife'
require 'chef/cookbook_loader'

module KnifeSpork
  class SporkCheck < Chef::Knife

    deps do
         require 'chef/json_compat'
         require 'uri'
         require 'chef/cookbook_version'
    end
    banner "knife spork check COOKBOOK"
    
    option :all,
      :short => "--a",
      :long => "--all",
      :description => "Show all uploaded versions of the cookbook"

    option :fail,
      :long => "--fail",
      :description => "If the check fails exit with non-zero exit code"
    
    def run

      if RUBY_VERSION.to_f < 1.9
        fail_and_exit("Sorry, knife-spork requires ruby 1.9 or newer.")
      end
      
      self.config = Chef::Config.merge!(config)
      @conf = AppConf.new
      
      if File.exists?("#{config[:cookbook_path].first.gsub("cookbooks","")}config/spork-config.yml")
        @conf.load("#{config[:cookbook_path].first.gsub("cookbooks","")}config/spork-config.yml")
        ui.msg "Loaded config file #{config[:cookbook_path].first.gsub("cookbooks","")}config/spork-config.yml...\n\n"
      end
      
      if File.exists?("/etc/spork-config.yml")
        @conf.load("/etc/spork-config.yml")
        ui.msg "Loaded config file /etc/spork-config.yml...\n\n"
      end
    
      if File.exists?(File.expand_path("~/.chef/spork-config.yml"))
        @conf.load(File.expand_path("~/.chef/spork-config.yml"))
        ui.msg "Loaded config file #{File.expand_path("~/.chef/spork-config.yml")}...\n\n"
      end

      if config.has_key?(:cookbook_path)
        cookbook_path = config["cookbook_path"]
      else
        fail_and_exit("No default cookbook_path; Specify with -o or fix your knife.rb.", :show_usage => true)
      end

      if name_args.size == 0
        show_usage
        exit 0
      end

      unless name_args.size == 1
        fail_and_exit("Please specify the cookbook whose version you which to check.", :show_usage => true)
      end

      cookbook = name_args.first
      cookbook_path = config[:cookbook_path]
      local_version = get_local_cookbook_version(cookbook_path, cookbook)
      remote_versions = get_remote_cookbook_versions(cookbook)

      check_versions(cookbook, local_version, remote_versions)
    end

    def get_local_cookbook_version(cookbook_path, cookbook)
      current_version = get_version(cookbook_path, cookbook).split(".").map{|i| i.to_i}
      metadata_file = File.join(cookbook_path, cookbook, "metadata.rb")
      local_version = current_version.join('.')
      return local_version
    end

    def get_remote_cookbook_versions(cookbook)
      env           = config[:environment]
      api_endpoint  = env ? "environments/#{env}/cookbooks/#{cookbook}" : "cookbooks/#{cookbook}"
      cookbooks = rest.get_rest(api_endpoint)
      versions = cookbooks[cookbook]["versions"]
      if config[:all]
        return versions
      else
        return versions[0..4]
      end
    end

    def check_versions(cookbook, local_version, remote_versions)

      conflict = false
      frozen = false
      ui.msg "Checking versions for cookbook #{cookbook}..."
      ui.msg ""
      ui.msg "Current local version: #{local_version}"
      ui.msg ""
      if config[:all]
        ui.msg "Remote versions:"
      else
        ui.msg "Remote versions (Max. 5 most recent only):"
      end
      remote_versions.each do |v|

        version_frozen = check_frozen(cookbook,v["version"])

        if version_frozen then
          pretty_frozen = "frozen"
        else
          pretty_frozen = "unfrozen"
        end

        if v["version"] == local_version then
          ui.msg "*" + v["version"] + ", " + pretty_frozen
          conflict = true
          if version_frozen then
            frozen = true
          end
        else
          ui.msg v["version"] + ", " + pretty_frozen
        end

      end
      ui.msg ""

      if conflict && frozen
        message = "DANGER: Your local cookbook has same version number as the starred version above!\n\nPlease bump your local version or you won't be able to upload."
        !config[:fail] ? ui.msg message ? fail_and_exit(message)
      elsif conflict && !frozen
        message = "DANGER: Your local cookbook version number clashes with an unfrozen remote version.\n\nIf you upload now, you'll overwrite it."
        !config[:fail] ? ui.msg message ? fail_and_exit(message)
      else
        ui.msg "Everything looks fine, no version clashes. You can upload!"
      end
    end

    def fail_and_exit(message, options={})
      ui.fatal message
      show_usage if options[:show_usage]
      exit 1
    end

    def get_version(cookbook_path, cookbook)
      loader = ::Chef::CookbookLoader.new(cookbook_path)
      return loader[cookbook].version
    end

    def check_frozen(cookbook,version)
      env           = config[:environment]
      api_endpoint  = env ? "environments/#{env}/cookbooks/#{cookbook}" : "cookbooks/#{cookbook}/#{version}"
      cookbooks = rest.get_rest(api_endpoint)
      cookbook_hash = cookbooks.to_hash
      return cookbook_hash["frozen?"]
    end
  end
end
