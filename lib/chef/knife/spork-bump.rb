#
# Modifying Author:: Jon Cowie (<jonlives@gmail.com>)
# Copyright:: Copyright (c) 2011 Jon Cowie
# License:: GPL

# Based on the knife-cookbook-bump plugin by:
# Alalanta (no license specified)

require 'app_conf'
require 'chef/knife'
require 'chef/cookbook_loader'
require 'chef/cookbook_uploader'

module KnifeSpork
  class SporkBump < Chef::Knife

    TYPE_INDEX = { "major" => 0, "minor" => 1, "patch" => 2, "manual" => 3 }

    banner "knife spork bump COOKBOOK [MAJOR|MINOR|PATCH|MANUAL]"

      @@gitavail = true
      deps do
        begin
          require "git"
        rescue LoadError
            @@gitavail = false
        end
      end

    def run

      if RUBY_VERSION.to_f < 1.9
        ui.fatal "Sorry, knife-spork requires ruby 1.9 or newer."
        exit 1
      end
      
      if File.exists?("/etc/spork-config.yml")
        AppConf.load("/etc/spork-config.yml")
        ui.msg "Loaded config file /etc/spork-config.yml...\n\n"
      end
    
      if File.exists?(File.expand_path("~/.chef/spork-config.yml"))
        AppConf.load(File.expand_path("~/.chef/spork-config.yml"))
        ui.msg "Loaded config file #{File.expand_path("~/.chef/spork-config.yml")}...\n\n"
      end
        
      bump_type=""

      self.config = Chef::Config.merge!(config)
      if config.has_key?(:cookbook_path)
        cookbook_path = config["cookbook_path"]
      else
        ui.fatal "No default cookbook_path; Specify with -o or fix your knife.rb."
        show_usage
        exit 1
      end

      if name_args.size == 0
        show_usage
        exit 0
      end

      if name_args.size == 3
        bump_type = name_args[1]
      elsif name_args.size == 2
        bump_type = name_args.last
      else
        ui.fatal "Please specify the cookbook whose version you which to bump, and the type of bump you wish to apply."
        show_usage
        exit 1
      end

      unless TYPE_INDEX.has_key?(bump_type)
        ui.fatal "Sorry, '#{name_args.last}' isn't a valid bump type.  Specify one of 'major', 'minor', 'patch' or 'manual'"
        show_usage
        exit 1
      end

      if bump_type == "manual"
        manual_version = name_args.last
        cookbook = name_args.first
        cookbook_path = Array(config[:cookbook_path]).first
        patch_type = "manual"
        patch_manual(cookbook_path, cookbook, manual_version)
      else
          cookbook = name_args.first
          patch_type = name_args.last
          cookbook_path = Array(config[:cookbook_path]).first
          patch(cookbook_path, cookbook, patch_type)
      end

      if !AppConf.git.nil? && AppConf.git.enabled
        if !@@gitavail
            ui.msg "Git gem not available, skipping git add.\n\n"
        else
            git_add(cookbook)
        end
      end
    end


    def patch(cookbook_path, cookbook, type)
      t = TYPE_INDEX[type]
      current_version = get_version(cookbook_path, cookbook).split(".").map{|i| i.to_i}
      bumped_version = current_version.clone
      bumped_version[t] = bumped_version[t] + 1
      while t < 2
        t+=1
        bumped_version[t] = 0
      end
      metadata_file = File.join(cookbook_path, cookbook, "metadata.rb")
      old_version = current_version.join('.')
      new_version = bumped_version.join('.')
      update_metadata(old_version, new_version, metadata_file)
      ui.msg("Bumping #{type} level of the #{cookbook} cookbook from #{old_version} to #{new_version}\n\n")
    end

    def patch_manual(cookbook_path, cookbook, version)
      current_version = get_version(cookbook_path, cookbook)
      v = version.split(".")
      if v.size < 3 or v.size > 3
        ui.msg "That isn't a valid version number to bump to."
        exit 1
      end

      v.each do |v_comp|
         if !v_comp.is_i?
           ui.msg "That isn't a valid version number to bump to."
           exit 1
         end
      end

      metadata_file = File.join(cookbook_path, cookbook, "metadata.rb")
      update_metadata(current_version, version, metadata_file)
      ui.msg("Manually bumped version of the #{cookbook} cookbook from #{current_version} to #{version}")
    end

    def update_metadata(old_version, new_version, metadata_file)
      open_file = File.open(metadata_file, "r")
      body_of_file = open_file.read
      open_file.close
      body_of_file.gsub!(old_version, new_version)
      File.open(metadata_file, "w") { |file| file << body_of_file }
    end

    def get_version(cookbook_path, cookbook)
      loader = ::Chef::CookbookLoader.new(cookbook_path)
      return loader[cookbook].version
    end

    def git_add(cookbook)
      strio = StringIO.new
      l = Logger.new strio
      cookbook_path = config[:cookbook_path]
      if cookbook_path.size > 1
        ui.warn "It looks like you have multiple cookbook paths defined so I can't tell if you're running inside a git repo.\n\n"
      else
        begin
          path = cookbook_path[0].gsub("cookbooks","")
          ui.msg "Opening git repo #{path}\n\n"
          g = Git.open(path, :log => Logger.new(strio))
          ui.msg "Git add'ing #{path}cookbooks/#{cookbook}/metadata.rb\n\n"
          g.add("#{path}cookbooks/#{cookbook}/metadata.rb")
        rescue ArgumentError => e
          ui.warn "Git: The root of your chef repo doesn't look like it's a git repo. Skipping git add...\n\n"
        rescue
          ui.warn "Git: Cookbook uploaded, but something went wrong with git add metadata.rb, Dumping log info..."
          ui.warn "#{strio.string}"
        end
      end
    end
  end

end

class String
    def is_i?
       !!(self =~ /^[-+]?[0-9]+$/)
    end
end
