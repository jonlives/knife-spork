require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class StatusNet < Plugin
      name :statusnet

      def perform; end

      def after_upload
        statusnet "#{organization}#{current_user} uploaded the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")}"
      end

      def after_delete
        statusnet "#{organization}#{current_user} deleted the following cookbooks: #{misc_output}"
      end

      def after_promote_remote
        statusnet "#{organization}#{current_user} promoted the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")} to #{environments.collect{ |e| "#{e.name}" }.join(", ")}"
      end

      def after_environmentfromfile
        statusnet "#{organization}#{current_user} uploaded environment #{object_name}"
      end

      def after_environmentedit
        statusnet "#{organization}#{current_user} edited environment #{object_name}"
      end

      def after_environmentcreate
        statusnet "#{organization}#{current_user} created environment #{object_name}"
      end

      def after_environmentdelete
        statusnet "#{organization}#{current_user} deleted environment #{object_name}"
      end

      def after_rolefromfile
        statusnet "#{organization}#{current_user} uploaded role #{object_name}"
      end

      def after_roleedit
        statusnet "#{organization}#{current_user} edited role #{object_name}"
      end

      def after_rolecreate
        statusnet "#{organization}#{current_user} created role #{object_name}"
      end

      def after_roledelete
        statusnet "#{organization}#{current_user} deleted role #{object_name}"
      end

      def after_databagedit
        statusnet "#{organization}#{current_user} edited data bag item #{object_name}:#{object_secondary_name}"
      end

      def after_databagcreate
        statusnet "#{organization}#{current_user} created data bag #{object_name}"
      end

      def after_databagdelete
        statusnet "#{organization}#{current_user} deleted data bag #{object_name}"
      end

      def after_databagitemdelete
        statusnet "#{organization}#{current_user} deleted data bag item #{object_name}:#{object_secondary_name}"
      end

      def after_databagfromfile
        statusnet "#{organization}#{current_user} uploaded data bag item #{object_name}:#{object_secondary_name}"
      end

      def after_nodeedit
        statusnet "#{organization}#{current_user} edited node #{object_name}"
      end

      def after_nodedelete
        statusnet "#{organization}#{current_user} deleted node #{object_name}"
      end

      def after_nodecreate
        statusnet "#{organization}#{current_user} created node #{object_name}"
      end

      def after_nodefromfile
        statusnet "#{organization}#{current_user} uploaded node #{object_name}"
      end

      def after_noderunlistadd
        statusnet "#{organization}#{current_user} added run_list items to #{object_name}: #{object_secondary_name}"
      end

      def after_noderunlistremove
        statusnet "#{organization}#{current_user} removed run_list items from #{object_name}: #{object_secondary_name}"
      end

      def after_noderunlistset
        statusnet "#{organization}#{current_user} set the run_list for #{object_name} to #{object_secondary_name}"
      end

      private

      def statusnet(message)
        safe_require 'curb'

        begin
          c = Curl::Easy.new(config.url)
          c.http_auth_types = :basic
          c.username = config.username
          c.password = config.password
          c.post_body = message
          c.perform
        rescue Exception => e
          ui.error 'Something went wrong sending to StatusNet.'
          ui.error e.to_s
        end
      end

    end
  end
end
