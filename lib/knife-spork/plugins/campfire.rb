require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Campfire < Plugin
      name :campfire

      def perform; end

      def after_upload
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} froze the following cookbooks on Chef Server:
#{cookbooks.collect{|c| "  #{c.name}@#{c.version}"}.join("\n")}
EOH
        end
      end

      def after_promote_remote
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} promoted cookbooks on Chef Server:

cookbooks:
#{cookbooks.collect{|c| "  #{c.name}@#{c.version}"}.join("\n")}

environments:
#{environments.collect{|e| "  #{e.name}"}.join("\n")}
EOH
        end
      end

      private
      def campfire(&block)
        safe_require 'tinder'

        rooms = [config.rooms || config.room].flatten.compact
        campfire = Tinder::Campfire.new(config.account, :token => config.token)

        rooms.each do |room_name|
          room = campfire.find_room_by_name(room_name)
          yield(room) unless room.nil?
        end
      end
    end
  end
end
