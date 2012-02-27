#
# Modifying Author:: Jon Cowie (<jonlives@gmail.com>)
# Copyright:: Copyright (c) 2011 Jon Cowie
# License:: Apache License, Version 2.0
#
# Modified cookbook upload to always freeze, and disable --force option
# Based on the knife cookbook upload plugin by:
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
require 'socket'

module KnifeSpork
  class SporkUpload < Chef::Knife

      CHECKSUM = "checksum"
      MATCH_CHECKSUM = /[0-9a-f]{32,}/

      deps do
        require 'chef/exceptions'
        require 'chef/cookbook_loader'
        require 'chef/cookbook_uploader'
      end

      banner "knife spork upload [COOKBOOKS...] (options)"

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      option :freeze,
        :long => '--freeze',
        :description => 'Freeze this version of the cookbook so that it cannot be overwritten',
        :boolean => true

      option :environment,
        :short => '-E',
        :long  => '--environment ENVIRONMENT',
        :description => "Set ENVIRONMENT's version dependency match the version you're uploading.",
        :default => nil

      option :depends,
        :short => "-d",
        :long => "--include-dependencies",
        :description => "Also upload cookbook dependencies"

      def run
        
        if RUBY_VERSION.to_f < 1.9
          ui.fatal "Sorry, knife-spork requires ruby 1.9 or newer."
          exit 1
        end
      
        self.config = Chef::Config.merge!(config)

        if File.exists?("#{config[:cookbook_path].first.gsub("cookbooks","")}config/spork-config.yml")
          AppConf.load("#{config[:cookbook_path].first.gsub("cookbooks","")}config/spork-config.yml")
          ui.msg "Loaded config file #{config[:cookbook_path].first.gsub("cookbooks","")}config/spork-config.yml...\n\n"
        end
      
        if File.exists?("/etc/spork-config.yml")
          AppConf.load("/etc/spork-config.yml")
          ui.msg "Loaded config file /etc/spork-config.yml...\n\n"
        end
      
        if File.exists?(File.expand_path("~/.chef/spork-config.yml"))
          AppConf.load(File.expand_path("~/.chef/spork-config.yml"))
          ui.msg "Loaded config file #{File.expand_path("~/.chef/spork-config.yml")}...\n\n"
        end
      
        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        assert_environment_valid!
        warn_about_cookbook_shadowing
        version_constraints_to_update = {}
        # Get a list of cookbooks and their versions from the server
        # for checking existence of dependending cookbooks.
        @server_side_cookbooks = Chef::CookbookVersion.list

        if @name_args.empty?
          show_usage
          ui.error("You must specify the --all flag or at least one cookbook name")
          exit 1
        end
        justify_width = @name_args.map {|name| name.size }.max.to_i + 2
        @name_args.each do |cookbook_name|
          begin
            cookbook = cookbook_repo[cookbook_name]
            if config[:depends]
              cookbook.metadata.dependencies.each do |dep, versions|
                @name_args.push dep
              end
            end
            ui.info("Uploading and freezing #{cookbook.name.to_s.ljust(justify_width + 10)} [#{cookbook.version}]")
            
            upload(cookbook, justify_width)
            cookbook.freeze_version
            upload(cookbook, justify_width)
            version_constraints_to_update[cookbook_name] = cookbook.version
                  
            if !AppConf.irccat.nil? && AppConf.irccat.enabled
                begin
                              
                  if !AppConf.irccat.channel?(String)
                    channels = AppConf.irccat.channel
                  else
                    channels = ["#{AppConf.irccat.channel}"]
                  end
                  
                  channels.each do |c|
                      message = "#{c} #BOLD#PURPLECHEF:#NORMAL #{ENV['USER']} uploaded and froze cookbook #TEAL#{cookbook_name}#NORMAL version #TEAL#{cookbook.version}#NORMAL"
                      s = TCPSocket.open(AppConf.irccat.server,AppConf.irccat.port)
                      s.write(message)
                      s.close
                  end
               rescue Exception => msg  
                puts "Something went wrong with sending to irccat: (#{msg})"  
               end
            end

            if !AppConf.eventinator.nil? && AppConf.eventinator.enabled
              metadata = {}
              metadata[:cookbook_name]    = cookbook.name
              metadata[:cookbook_version] = cookbook.version

              event_data = {}
              event_data[:tag]      = "knife"
              event_data[:username] = ENV['USER']
              event_data[:status]   = "#{ENV['USER']} uploaded and froze version #{cookbook.version} of cookbook #{cookbook_name}"
              event_data[:metadata] = metadata.to_json

              uri = URI.parse(AppConf.eventinator.url)

              http = Net::HTTP.new(uri.host, uri.port)

              ## TODO: should make this configurable, timeout after 5 sec
              http.read_timeout = 5;

              request = Net::HTTP::Post.new(uri.request_uri)
              request.set_form_data(event_data)

              begin
                response = http.request(request)
                if response.code != "200"
                  ui.warn("Got a #{response.code} from #{AppConf.eventinator.url} upload wasn't eventinated")
                end 
              rescue Timeout::Error
                ui.warn("Timed out connecting to #{AppConf.eventinator.url} upload wasn't eventinated")
              rescue Exception => msg
                ui.warn("An unhandled execption occured while eventinating: #{msg}")
              end 
            end 

          rescue Chef::Exceptions::CookbookNotFoundInRepo => e
            ui.error("Could not find cookbook #{cookbook_name} in your cookbook path, skipping it")
            Chef::Log.debug(e)
          end
        end

        ui.info "upload complete"
        update_version_constraints(version_constraints_to_update) if config[:environment]
      end

      def cookbook_repo
        @cookbook_loader ||= begin
          Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, config[:cookbook_path]) }
          Chef::CookbookLoader.new(config[:cookbook_path])
        end
      end

      def update_version_constraints(new_version_constraints)
        new_version_constraints.each do |cookbook_name, version|
          environment.cookbook_versions[cookbook_name] = "= #{version}"
        end
        environment.save
      end


      def environment
        @environment ||= config[:environment] ? Chef::Environment.load(config[:environment]) : nil
      end

      def warn_about_cookbook_shadowing
        unless cookbook_repo.merged_cookbooks.empty?
          ui.warn "* " * 40
          ui.warn(<<-WARNING)
The cookbooks: #{cookbook_repo.merged_cookbooks.join(', ')} exist in multiple places in your cookbook_path.
A composite version of these cookbooks has been compiled for uploading.

#{ui.color('IMPORTANT:', :red, :bold)} In a future version of Chef, this behavior will be removed and you will no longer
be able to have the same version of a cookbook in multiple places in your cookbook_path.
WARNING
          ui.warn "The affected cookbooks are located:"
          ui.output ui.format_for_display(cookbook_repo.merged_cookbook_paths)
          ui.warn "* " * 40
        end
      end

      private

      def assert_environment_valid!
        environment
      rescue Net::HTTPServerException => e
        if e.response.code.to_s == "404"
          ui.error "The environment #{config[:environment]} does not exist on the server, aborting."
          Chef::Log.debug(e)
          exit 1
        else
          raise
        end
      end

      def upload(cookbook, justify_width)

        check_for_broken_links(cookbook)
        check_dependencies(cookbook)
        Chef::CookbookUploader.new(cookbook, config[:cookbook_path]).upload_cookbook
      rescue Net::HTTPServerException => e
        case e.response.code
        when "409"
          ui.error "Version #{cookbook.version} of cookbook #{cookbook.name} is frozen. Please bump your version number."
          Chef::Log.debug(e)
        else
          raise
        end
      end

      # if only you people wouldn't put broken symlinks in your cookbooks in
      # the first place. ;)
      def check_for_broken_links(cookbook)
        # MUST!! dup the cookbook version object--it memoizes its
        # manifest object, but the manifest becomes invalid when you
        # regenerate the metadata
        broken_files = cookbook.dup.manifest_records_by_path.select do |path, info|
          info[CHECKSUM].nil? || info[CHECKSUM] !~ MATCH_CHECKSUM
        end
        unless broken_files.empty?
          broken_filenames = Array(broken_files).map {|path, info| path}
          ui.error "The cookbook #{cookbook.name} has one or more broken files"
          ui.info "This is probably caused by broken symlinks in the cookbook directory"
          ui.info "The broken file(s) are: #{broken_filenames.join(' ')}"
          exit 1
        end
      end

      def check_dependencies(cookbook)
        # for each dependency, check if the version is on the server, or
        # the version is in the cookbooks being uploaded. If not, exit and warn the user.
        cookbook.metadata.dependencies.each do |cookbook_name, version|
          unless check_server_side_cookbooks(cookbook_name, version) || check_uploading_cookbooks(cookbook_name, version)
            # warn the user and exit
            ui.error "Cookbook #{cookbook.name} depends on cookbook #{cookbook_name} version #{version},"
            ui.error "which is not currently being uploaded and cannot be found on the server."
            exit 1
          end
        end
      end

      def check_server_side_cookbooks(cookbook_name, version)
        if @server_side_cookbooks[cookbook_name].nil?
          false
        else
          @server_side_cookbooks[cookbook_name]["versions"].each do |versions_hash|
            return true if Chef::VersionConstraint.new(version).include?(versions_hash["version"])
          end
          false
        end
      end

      def check_uploading_cookbooks(cookbook_name, version)
        if config[:all]
          # check from all local cookbooks in the path
          unless cookbook_repo[cookbook_name].nil?
            return Chef::VersionConstraint.new(version).include?(cookbook_repo[cookbook_name].version)
          end
        else
          # check from only those in the command argument
          if @name_args.include?(cookbook_name)
            return Chef::VersionConstraint.new(version).include?(cookbook_repo[cookbook_name].version)
          end
        end
        false
      end

    end
  end
