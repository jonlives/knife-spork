#
# Author:: Jon Cowie (<jonlives@gmail.com>)
# Copyright:: Copyright (c) 2011 Jon Cowie
# License:: Apache License, Version 2.0
#
#
# Uses some code from the knife cookbook upload plugin by:
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

require 'app_conf'
require 'chef/knife'
require 'json'
require 'socket'
require 'hipchat'

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
        
        if RUBY_VERSION.to_f < 1.9
          ui.fatal "Sorry, knife-spork requires ruby 1.9 or newer."
          exit 1
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
        
        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        if @name_args.empty? && @conf.default_environments.nil?
          show_usage
          ui.error("You must specify a cookbook name and an environment")
          exit 1
        elsif @name_args.empty? && !@conf.default_environments.nil?
          show_usage
          ui.error("Default environments loaded from config, but you must specify a cookbook name")
          exit 1
        elsif @name_args.size != 2 && @conf.default_environments.nil?
          show_usage
          ui.error("You must specify a cookbook name and an environment")
          exit 1
        end
        
        if !@conf.git.nil? && @conf.git.enabled
          if !@@gitavail
              ui.msg "Git gem not available, skipping git pull.\n\n"
          else
              git_pull_if_repo
          end
        end
        
        if @conf.default_environments.nil?
            environments = [ @name_args[0] ]
            @cookbook = @name_args[1]
        elsif !@conf.default_environments.nil? && @name_args.size == 2
            environments = [ @name_args[0] ]
            @cookbook = @name_args[1]
        else
            environments = @conf.default_environments
            @cookbook = @name_args[0]
        end
        
        check_cookbook_uploaded(@cookbook)
        
        environments.each do |e|
              ui.msg ""
              ui.msg "Environment: #{e}"
              
              cookbook_path = config[:cookbook_path]
              if cookbook_path.size > 1
                @environment = loader.load_from("environments", "#{e}.json")
              else
                path = cookbook_path[0].gsub("cookbooks","environments") + "/#{e}.json"
                 @environment = loader.object_from_file("#{path}")
              end
              
              if @cookbook == "all"
                ui.msg "Promoting ALL cookbooks to environment #{@environment}"
                cookbook_names = get_all_cookbooks
                cookbook_names.each do |c|
                  @environment = promote(@environment, c)
                end
              else
                @environment = promote(@environment, @cookbook)
              end

              ui.msg "Saving changes into #{e}.json"
              new_environment_json = pretty_print(@environment)
              save_environment_changes(e,new_environment_json)
          
              if config[:remote]
                ui.msg "Uploading #{e} to server"
                save_environment_changes_remote("#{e}")
                ui.info "\nPromotion complete, and environment uploaded."
              else
                ui.info "\nPromotion complete! Please remember to upload your changed #{e}.json to the Chef Server."
              end
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
          
          cookbook_path = config[:cookbook_path]
          if cookbook_path.size > 1
              updated = loader.load_from("environments", "#{environment}.json")
          else
              path = cookbook_path[0].gsub("cookbooks","environments") + "/#{environment}.json"
              updated = loader.object_from_file("#{path}")
          end
          
          env_server = Chef::Environment.load(environment.gsub(".json","")).to_hash["cookbook_versions"]
          env_local = updated.to_hash["cookbook_versions"]
          env_diff = env_server.diff(env_local)
          
          if env_diff.size > 1
            ui.warn "You're about to promote changes to several cookbooks:"
            ui.warn "\n#{env_diff.collect { |k, v| "#{k}: #{v}\n" }.join}"
            begin
              ui.confirm("Are you sure you want to continue")
            rescue SystemExit => e
                if e.status == 3
                  ui.confirm("Would you like to reset your local #{environment}.json to match the server?")
                  tmp_env = Chef::Environment.load(environment)
                  save_environment_changes(environment,pretty_print(tmp_env))
                  puts "#{environment}.json reset."
                end
                raise
            end
          end
          updated.save

          if !@conf.gist.nil? && @conf.gist.enabled
            if @conf.gist.in_chef
              gist_path = @conf.gist.chef_path
            else
              gist_path = @conf.gist.path
            end
            
            msg = "Environment #{environment.gsub(".json","")} uploaded at #{Time.now.getutc} by #{ENV['USER']}\n\nConstraints updated on server in this version:\n\n#{env_diff.collect { |k, v| "#{k}: #{v}\n" }.join}"
            @gist = %x[ echo "#{msg}" | #{gist_path}]
          end
          
          if !@conf.irccat.nil? && @conf.irccat.enabled   
            begin
              
              if !@conf.irccat.channel?(String)
                channels = @conf.irccat.channel
              else
                channels = ["#{@conf.irccat.channel}"]
              end
              
              channels.each do |c|   
                message = "#{c} #BOLD#PURPLECHEF:#NORMAL #{ENV['USER']} uploaded environment #TEAL#{environment.gsub(".json","")}#NORMAL #{@gist}"
                s = TCPSocket.open(@conf.irccat.server,@conf.irccat.port)
                s.write(message)
                s.close
              end
            rescue Exception => msg  
              puts "Something went wrong with sending to irccat: (#{msg})"  
            end
          end

          if !@conf.hipchat.nil? && @conf.hipchat.enabled
              begin
                message = "#{ENV['USER']} uploaded environment #{environment.gsub(".json","")} #{@gist}"
                client = HipChat::Client.new(@conf.hipchat.apikey)
                client["#{@conf.hipchat.room}"].send( @conf.hipchat.nickname, message, :notify => @conf.hipchat.notify, :color => @conf.hipchat.color )
              rescue Exception => msg
                puts "Something went wrong with sending to HipChat: (#{msg})"
              end
          end
            
          if !@conf.eventinator.nil? && @conf.eventinator.enabled
            metadata = {}
            metadata[:promoted_cookbooks] = {}
            promoted_cookbooks = []
            env_diff.collect do |k,v|
              v =~ /= ([\d\.]+) changed to = ([\d\.]+)/
              metadata[:promoted_cookbooks][k] = { :previous_version => $1, :new_version => $2 }
              promoted_cookbooks << "#{k} (#{$2})"
            end
            event_data = {}
            event_data[:tag]      = "knife"
            event_data[:username] = ENV['USER']
            event_data[:status]   = "#{ENV['USER']} promoted #{promoted_cookbooks.join(", ")} to #{environment.gsub(".json","")}"
            event_data[:metadata] = metadata.to_json
            uri = URI.parse(@conf.eventinator.url)
            http = Net::HTTP.new(uri.host, uri.port)
            ## TODO: should make this configurable, timeout after 5 sec
            http.read_timeout = 5;
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(event_data)
            begin
              response = http.request(request)
              if response.code != "200"
                ui.warn("Got a #{response.code} from #{@conf.eventinator.url} promote wasn't eventinated")
              end 
            rescue Timeout::Error
              ui.warn("Timed out connecting to #{@conf.eventinator.url} promote wasn't eventinated")
            rescue Exception => msg 
              ui.warn("An unhandled execption occured while eventinating: #{msg}")
            end 
          end
          if !@conf.graphite.nil? && @conf.graphite.enabled
            begin
              time = Time.now
              message = "deploys.chef.#{environment.gsub(".json","")} 1 #{time.to_i}\n"
              s = TCPSocket.open(@conf.graphite.server,@conf.graphite.port)
              s.write(message)
              s.close
            rescue Exception => msg  
              puts "Something went wrong with sending to graphite: (#{msg})"  
            end
          end
      end

      def save_environment_changes(environment,envjson)
        cookbook_path = config[:cookbook_path]

        if cookbook_path.size > 1
          ui.warn "It looks like you have multiple cookbook paths defined so I'm trying the first one (#{cookbook_path[0]}).\n\n"
        end
        path = cookbook_path[0].gsub("cookbooks","environments") + "/#{environment}.json"

        File.open(path, 'w') do |f2|
          # use "\n" for two lines of text
          f2.puts envjson
        end
        if !@conf.git.nil? && @conf.git.enabled
            if !@@gitavail
              ui.msg "Git gem not available, skipping git add.\n\n"
            else
              git_add(path)
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
     
      def check_cookbook_uploaded(cookbook)
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
        ui.msg "Checking that #{cookbook} version #{@version} exists on the server before promoting (any error means it hasn't been uploaded yet)...\n\n"
        env           = config[:environment]
        api_endpoint  = env ? "environments/#{env}/cookbooks/#{cookbook}/#{@version}" : "cookbooks/#{cookbook}/#{@version}"
        cookbooks = rest.get_rest(api_endpoint)
        ui.msg "#{cookbook} version #{@version } found on server!"
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
            path = cookbook_path[0].gsub("/cookbooks","")
            ui.msg "Opening git repo #{path}\n\n"
            g = Git.open(path, :log => Logger.new(strio))
            ui.msg "Pulling latest changes from git\n\n"
            output = IO.popen ("cd #{path} && git pull 2>&1")
            Process.wait
            exit_code = $?            
            if exit_code.exitstatus ==  0
              ui.msg "#{output.read()}\n"
            else
              ui.error "#{output.read()}\n"
              exit 1
            end

            ui.msg "Pulling latest changes from git submodules (if any)\n\n"
            output = IO.popen ("cd #{path} && git submodule foreach git pull 2>&1")
            Process.wait
            exit_code = $?
            if exit_code.exitstatus ==  0
              ui.msg "#{output.read()}\n"
            else
              ui.error "#{output.read()}\n"
              exit 1
            end
          rescue ArgumentError => e
            ui.warn "Git: The root of your chef repo doesn't look like it's a git repo. Skipping git pull...\n\n"
          end
        end
     end
     
      def git_add(environment)
      strio = StringIO.new
      l = Logger.new strio
      cookbook_path = config[:cookbook_path]
      begin
        path = cookbook_path[0].gsub("cookbooks","")
        ui.msg "Opening git repo #{path}\n\n"
        g = Git.open(path, :log => Logger.new(strio))
        ui.msg "Git add'ing #{environment}\n\n"
        g.add("#{environment}")
      rescue ArgumentError => e
        ui.warn "Git: The root of your chef repo doesn't look like it's a git repo. Skipping git add...\n\n"
      rescue
        ui.warn "Git: Cookbook bump succeeded, but something went wrong with git add #{environment}, so you'll want to manually git add it. Dumping log info..."
        ui.warn "#{strio.string}"
      end
     end
  end
end
class String
      def is_i?
         !!(self =~ /^[-+]?[0-9]+$/)
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
