#
# Modifying Author:: Jon Cowie (<jonlives@gmail.com>)
# Copyright:: Copyright (c) 2011 Jon Cowie
# License:: GPL

# Based on the knife-cookbook-bump plugin by:
# Alalanta (no license specified)

require 'chef/knife'
require 'chef/cookbook_loader'
require 'chef/cookbook_uploader'

module Jonlives
  class SporkBump < Chef::Knife

    TYPE_INDEX = { "major" => 0, "minor" => 1, "patch" => 2 }

    banner "knife spork bump COOKBOOK [MAJOR|MINOR|PATCH]"


    def run
  
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

      unless name_args.size == 2
        ui.fatal "Please specify the cookbook whose version you which to bump, and the type of bump you wish to apply."
        show_usage
        exit 1
      end
    
      unless TYPE_INDEX.has_key?(name_args.last.downcase)
        ui.fatal "Sorry, '#{name_args.last}' isn't a valid bump type.  Specify one of 'major', 'minor' or 'patch'"
        show_usage
        exit 1
      end
      cookbook = name_args.first
      patch_type = name_args.last
      cookbook_path = Array(config[:cookbook_path]).first

      patch(cookbook_path, cookbook, patch_type)

    end


    def patch(cookbook_path, cookbook, type)
      t = TYPE_INDEX[type]
      current_version = get_version(cookbook_path, cookbook).split(".").map{|i| i.to_i}
      bumped_version = current_version.clone
      bumped_version[t] = bumped_version[t] + 1
      metadata_file = File.join(cookbook_path, cookbook, "metadata.rb")
      old_version = current_version.join('.')
      new_version = bumped_version.join('.') 
      update_metadata(old_version, new_version, metadata_file)
      ui.msg("Bumping #{type} level of the #{cookbook} cookbook from #{old_version} to #{new_version}")
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
  end
end
