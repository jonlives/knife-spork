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

      def after_rolefromfile
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} uploaded role #{object_name}
          EOH
        end
      end

      def after_roleedit
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} edited role #{object_name}
          EOH
        end
      end

      def after_rolecreate
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} created role #{object_name}
          EOH
        end
      end

      def after_roledelete
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} deleted role #{object_name}
          EOH
        end
      end

      def after_databagedit
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} edited data bag item #{object_name}:#{object_secondary_name}
          EOH
        end
      end

      def after_databagdelete
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} deleted data bag #{object_name}}
          EOH
        end
      end

      def after_databagitemdelete
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} deleted data bag item #{object_name}:#{object_secondary_name}
          EOH
        end
      end

      def after_databagcreate
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} created data bag #{object_name}
          EOH
        end
      end

      def after_databagfromfile
        campfire do |rooms|
          rooms.paste <<-EOH
#{organization}#{current_user} uploaded data bag item #{object_name}:#{object_secondary_name}
          EOH
        end
      end

      private
      def campfire(&block)
        safe_require 'campy'

        rooms = [config.rooms || config.room].flatten.compact
        campfire = Campy::Room.new(:account => config.account, :token => config.token)

        rooms.each do |room_name|
          room = Campy::Room.new(
            :account => config.account,
            :token => config.token,
            :room => room_name
          )
          yield(room) unless room.nil?
        end
      end
    end
  end
end
