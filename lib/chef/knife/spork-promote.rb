#
# Author:: Jon Cowie (<jonlives@gmail.com>)
# Copyright:: Copyright (c) 2011 Jon Cowie
# License:: Apache License, Version 2.0
#
#
# Uses code from the knife cookbook upload plugin by:
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Nuo Yan (<yan.nuo@gmail.com>)
# Copyright:: Copyright (c) 2009, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'
require 'json'

module KnifeSpork
  class SporkPromote < Chef::Knife

      @@gitavail = true
      deps do
        require 'chef/exceptions'
        require 'chef/cookbook_loader'
        require 'chef/knife/core/object_loader'
        begin
          require "git"
        rescue LoadError
            @@gitavail = false
        end
      end

      banner "knife spork promote ENVIRONMENT COOKBOOK (options)"

      option :version,
        :short => '-v',
        :long  => '--version VERSION',
        :description => "Set the environment's version constraint to the specified version",
        :default => nil

      option :remote,
        :long  => '--remote',
        :description => "Save the environment to the chef server in addition to the local JSON file",
        :default => nil

      def run
        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        if @name_args.empty?
          show_usage
          ui.error("You must specify a cookbook name and an environment")
          exit 1
        elsif @name_args.size != 2
          show_usage
          ui.error("You must specify a cookbook name and an environment")
          exit 1
        end

        if !@@gitavail
            ui.msg "Git gem not available, skipping git pull.\n\n"
        else
            git_pull_if_repo
        end

        @cookbook = @name_args[1]
        @environment = loader.load_from("environments", @name_args[0] + ".json")

        if @cookbook == "all"
          ui.msg "Promoting ALL cookbooks to environment #{@environment}\n\n"
          cookbook_names = get_all_cookbooks
          cookbook_names.each do |c|
            @environment = promote(@environment, c)
          end
        else
          @environment = promote(@environment, @cookbook)
        end

        ui.msg "\nSaving changes into #{@name_args[0]}.json"
        new_environment_json = pretty_print(@environment)
        save_environment_changes(@name_args[0],new_environment_json)

        if config[:remote]
          ui.msg "\nUploading #{@name_args[0]} to server"
          save_environment_changes_remote(@name_args[0] + ".json")
          ui.info "\nPromotion complete, and environment uploaded."
        else
          ui.info "\nPromotion complete! Please remember to upload your changed Environment file to the Chef Server."
        end

      end

      def update_version_constraints(environment,cookbook,version_constraint)
        environment.cookbook_versions[cookbook] = "= #{version_constraint}"
        return environment
      end

      def get_version(cookbook_path, cookbook)
        loader = ::Chef::CookbookLoader.new(cookbook_path)
        return loader[cookbook].version
      end

      def load_environment(env)
         e = Chef::Environment.load(env)
         ejson = JSON.parse(e.to_json)
         puts JSON.pretty_generate(ejson)
         return e
         rescue Net::HTTPServerException => e
           if e.response.code.to_s == "404"
             ui.error "The environment #{env} does not exist on the server, aborting."
             Chef::Log.debug(e)
             exit 1
           else
             raise
           end
      end

       def valid_version(version)
          v = version.split(".")
          if v.size < 3 or v.size > 3
            return false
          end
          v.each do |v_comp|
             if !v_comp.is_i?
               return false
             end
          end
          return true
      end

      def loader
        @loader ||= Chef::Knife::Core::ObjectLoader.new(Chef::Environment, ui)
      end

      def save_environment_changes_remote(environment)
          @loader ||= Knife::Core::ObjectLoader.new(Chef::Environment, ui)
          updated = loader.load_from("environments", environment)
          updated.save
      end

      def save_environment_changes(environment,envjson)
        cookbook_path = config[:cookbook_path]

        if cookbook_path.size > 1
          ui.warn "It looks like you have multiple cookbook paths defined so I'm not sure where to save your changed environment file.\n\n"
          ui.msg "Here's the JSON for you to paste into #{environment}.json in the environments directory you wish to use.\n\n"
          ui.msg "#{envjson}\n\n"
        else
          path = cookbook_path[0].gsub("cookbooks","environments") + "/#{environment}.json"

          File.open(path, 'w') do |f2|
            # use "\n" for two lines of text
            f2.puts envjson
          end
        end
      end

      def promote(environment,cookbook)

        if config[:version]
            if !valid_version(config[:version])
              ui.error("#{config[:version]} isn't a valid version number.")
              return 1
            else
              @version = config[:version]
            end
        else
           @version = get_version(config[:cookbook_path], cookbook)
        end

        ui.msg "Adding version constraint #{cookbook} = #{@version}"
        return update_version_constraints(environment,cookbook,@version)
      end

      def get_all_cookbooks
          results = []
          cookbooks = ::Chef::CookbookLoader.new(config[:cookbook_path])
          cookbooks.each do |c|
            results << c
          end
          return results
     end

     def pretty_print(environment)
       return JSON.pretty_generate(JSON.parse(environment.to_json))
     end

     def git_pull_if_repo
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
            ui.msg "Pulling latest changes from git\n\n"
            g.pull
          rescue ArgumentError => e
            puts "Git Error: The root of your chef repo doesn't look like it's a git repo. Skipping git pull...\n\n"
          rescue
            puts "Git Error: Something went wrong, Dumping log info..."
            puts "#{strio.string}"
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
