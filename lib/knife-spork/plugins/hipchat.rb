require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class HipChat < Plugin
      name :hipchat

      def perform; end

      def after_upload
        hipchat "#{organization}#{current_user} uploaded the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")}"
      end

      def after_promote_remote
        hipchat "#{organization}#{current_user} promoted the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")} to #{environments.collect{ |e| "#{e.name}" }.join(", ")}"
      end

      def after_rolefromfile
        hipchat "#{organization}#{current_user} uploaded role #{role_name}"
      end

      def after_roleedit
        hipchat "#{organization}#{current_user} edited role #{role_name}"
      end

      def after_rolecreate
        hipchat "#{organization}#{current_user} created role #{role_name}"
      end

      def after_roledelete
        hipchat "#{organization}#{current_user} deleted role #{role_name}"
      end

      private
      def hipchat(message)
        safe_require 'hipchat'

        rooms.each do |room_name|
          begin
            client = ::HipChat::Client.new(config.api_token)
            client[room_name].send(nickname, message, :notify => notify, :color =>color)
          rescue Exception => e
            ui.error 'Something went wrong sending to HipChat.'
            ui.error e.to_s
          end
        end
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
