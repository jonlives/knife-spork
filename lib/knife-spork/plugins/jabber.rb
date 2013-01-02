require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Jabber < Plugin
      name :jabber

      def perform; end

      def after_upload
        jabber "#{current_user} uploaded the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")}"
      end

      def after_promote_remote
        jabber "#{current_user} promoted the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")} to #{environments.collect{ |e| "#{e.name}" }.join(", ")}"
      end

      private

      def jabber(message)
        safe_require 'xmpp4r'
        safe_require 'xmpp4r/muc/helper/simplemucclient'

        client = ::Jabber::Client.new(config.username)
        client.connect(host = config.server_name, port = config.server_port ||= '5222')
        client.auth(config.password)

        rooms.each do |room_name|
          begin
            conference = ::Jabber::MUC::SimpleMUCClient.new(client)
            conference.join("#{room_name}/#{nickname}")
            conference.say(message)
          rescue Exception => e
            ui.error 'Something went wrong sending to Jabber.'
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
    end
  end
end
