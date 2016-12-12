require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Slack < Plugin
      name :slack

      def perform; end

      def after_upload
        slack "#{organization}#{current_user} uploaded the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")}"
      end

      def after_delete
        slack "#{organization}#{current_user} deleted the following cookbooks: #{misc_output}"
      end

      def after_promote_remote
        slack "#{organization}#{current_user} promoted the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")} to #{environments.collect{ |e| "#{e.name}" }.join(", ")}"
      end

      def after_environmentfromfile
        slack "#{organization}#{current_user} uploaded environment #{object_name}"
      end

      def after_environmentedit
        slack "#{organization}#{current_user} edited environment #{object_name}"
      end

      def after_environmentcreate
        slack "#{organization}#{current_user} created environment #{object_name}"
      end

      def after_environmentdelete
        slack "#{organization}#{current_user} deleted environment #{object_name}"
      end

      def after_rolefromfile
        slack "#{organization}#{current_user} uploaded role #{object_name}"
      end

      def after_roleedit
        slack "#{organization}#{current_user} edited role #{object_name}"
      end

      def after_rolecreate
        slack "#{organization}#{current_user} created role #{object_name}"
      end

      def after_roledelete
        slack "#{organization}#{current_user} deleted role #{object_name}"
      end

      def after_databagedit
        slack "#{organization}#{current_user} edited data bag item #{object_name}:#{object_secondary_name}"
      end

      def after_databagcreate
        slack "#{organization}#{current_user} created data bag #{object_name}"
      end

      def after_databagdelete
        slack "#{organization}#{current_user} deleted data bag item #{object_name}"
      end

      def after_databagitemdelete
        slack "#{organization}#{current_user} deleted data bag item #{object_name}:#{object_secondary_name}"
      end

      def after_databagfromfile
        slack "#{organization}#{current_user} uploaded data bag item #{object_name}:#{object_secondary_name}"
      end

      def after_nodeedit
        slack "#{organization}#{current_user} edited node #{object_name}"
      end

      def after_nodedelete
        slack "#{organization}#{current_user} deleted node #{object_name}"
      end

      def after_nodecreate
        slack "#{organization}#{current_user} created node #{object_name}"
      end

      def after_nodefromfile
        slack "#{organization}#{current_user} uploaded node #{object_name}"
      end

      def after_noderunlistadd
        slack "#{organization}#{current_user} added run_list items to #{object_name}: #{object_secondary_name}"
      end

      def after_noderunlistremove
        slack "#{organization}#{current_user} removed run_list items from #{object_name}: #{object_secondary_name}"
      end

      def after_noderunlistset
        slack "#{organization}#{current_user} set the run_list for #{object_name} to #{object_secondary_name}"
      end


      private
      def slack(message)
        safe_require 'slack-notifier'
        begin
          notifier = ::Slack::Notifier.new( config.webhook_url, channel: channel, username: username, icon_url: config.icon_url)
          notifier.ping message 
        rescue Exception => e
          ui.error 'Something went wrong sending to Slack.'
          ui.error e.to_s
        end
      end

      def channel
        config.channel || '#random'
      end

      def username
        config.username || 'KnifeSpork'
      end

    end
  end
end
