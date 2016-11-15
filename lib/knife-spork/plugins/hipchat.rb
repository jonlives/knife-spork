require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class HipChat < Plugin
      name :hipchat

      def perform; end

      def after_upload
        hipchat "#{organization}#{current_user} uploaded the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")}"
      end

      def after_delete
        hipchat "#{organization}#{current_user} deleted the following cookbooks: #{misc_output}"
      end

      def after_promote_remote
	      environments.each do |environment|
          diff = environment_diffs[environment.name]
          env_gist = env_gist(environment, diff) if config.gist
          hipchat "#{organization}#{current_user} promoted the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")} to #{environment} #{env_gist}"
	      end
      end

      def after_environmentfromfile
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} uploaded environment #{object_name} #{environment_gist}"
      end

      def after_environmentedit
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} edited environment #{object_name} #{environment_gist}"
      end

      def after_environmentcreate
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} created environment #{object_name} #{environment_gist}"
      end

      def after_environmentdelete
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} deleted environment #{object_name} #{environment_gist}"
      end

      def after_rolefromfile
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} uploaded role #{object_name} #{role_gist}"
      end

      def after_roleedit
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} edited role #{object_name} #{role_gist}"
      end

      def after_rolecreate
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} created role #{object_name} #{role_gist}"
      end

      def after_roledelete
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} deleted role #{object_name} #{role_gist}"
      end

      def after_databagedit
        databag_gist = object_gist("databag item", "#{object_name}:#{object_secondary_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} edited data bag item #{object_name}:#{object_secondary_name} #{databag_gist}"
      end

      def after_databagcreate
        databag_gist = object_gist("databag item", "#{object_name}:#{object_secondary_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} created data bag #{object_name} #{databag_gist}"
      end

      def after_databagdelete
        databag_gist = object_gist("databag item", "#{object_name}:#{object_secondary_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} deleted data bag item #{object_name} #{databag_gist}"
      end

      def after_databagitemdelete
        databag_gist = object_gist("databag item", "#{object_name}:#{object_secondary_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} deleted data bag item #{object_name}:#{object_secondary_name} #{databag_gist}"
      end

      def after_databagfromfile
        databag_gist = object_gist("databag item", "#{object_name}:#{object_secondary_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} uploaded data bag item #{object_name}:#{object_secondary_name} #{databag_gist}"
      end

      def after_nodeedit
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} edited node #{object_name} #{node_gist}"
      end

      def after_nodedelete
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} deleted node #{object_name} #{node_gist}"
      end

      def after_nodecreate
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} created node #{object_name} #{node_gist}"
      end

      def after_nodefromfile
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} uploaded node #{object_name} #{node_gist}"
      end

      def after_noderunlistadd
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} added run_list items to #{object_name}: #{object_secondary_name} #{node_gist}"
      end

      def after_noderunlistremove
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} removed run_list items from #{object_name}: #{object_secondary_name} #{node_gist}"
      end

      def after_noderunlistset
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        hipchat "#{organization}#{current_user} set the run_list for #{object_name} to #{object_secondary_name} #{node_gist}"
      end


      private
      def hipchat(message)
        safe_require 'hipchat'

        rooms.each do |room_name|
          begin
            client = ::HipChat::Client.new(config.api_token, :api_version => config.api_version ||= 'v1', :server_url => config.server_url ||= 'https://api.hipchat.com')
            client[room_name].send(nickname, message, :notify => notify, :color =>color)
          rescue Exception => e
            ui.error 'Something went wrong sending to HipChat.'
            ui.error e.to_s
          end
        end
      end

      def env_gist(environment, diff)
        msg = "Environment #{environment} uploaded at #{Time.now.getutc} by #{current_user}\n\nConstraints updated on server in this version:\n\n#{diff.collect { |k, v| "#{k}: #{v}\n" }.join}"
        link = %x[ echo "#{msg}" | #{config.gist}]
        return "<a href=\"#{link}\">Diff</a>" if !link.nil? || !link.empty?
      end

      def object_gist(object_type, object_name, object_diff)
        msg = "#{object_type.capitalize} #{object_name} changed at #{Time.now.getutc} by #{current_user}\n\nDiff is as follows:\n\n#{object_diff}"
        link = %x[ echo "#{msg}" | #{config.gist}]
        return "<a href=\"#{link}\">Diff</a>" if !link.nil? || !link.empty?
      end

      def rooms
        [ config.room || config.rooms ].flatten
      end

      def nickname
        config.nickname || 'KnifeSpork'
      end

      def notify
        config.notify.nil? ? true : config.notify
      end

      def color
        config.color || 'yellow'
      end
    end
  end
end
