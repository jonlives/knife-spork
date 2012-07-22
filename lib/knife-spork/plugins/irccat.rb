require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Irccat < Plugin
      name :irccat

      def perform; end

      def after_upload
        irccat("#BOLD#PURPLECHEF:#NORMAL #{current_user} uploaded\n#TEAL#{cookbooks.collect{ |c| "#{c.name}@#{c.version}" }.join("\n")}#NORMAL")
      end

      def after_promote
        irccat("#BOLD#PURPLECHEF:#NORMAL #{current_user} promoted\n#TEAL#{cookbooks.collect{ |c| "#{c.name}@#{c.version}" }.join("\n")}#NORMAL")
      end

      private
      def irccat(message)
        channels.each do |channel|
          begin
            # Write the message using a TCP Socket
            socket = TCPSocket.open(config.server, config.port)
            socket.write("#{channel} #{message}")
          rescue Exception => e
            ui.error 'Failed to post message with irccat.'
            ui.error e.to_s
          ensure
            socket.close unless socket.nil?
          end
        end
      end

      def channels
        [ config.channel || config.channels ].flatten
      end
    end
  end
end
