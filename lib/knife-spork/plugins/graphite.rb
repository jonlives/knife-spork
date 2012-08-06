require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Graphite < Plugin
      name :graphite
      hooks :after_promote_remote

      def perform
        environments.each do |environment|
          begin
            message = "deploys.chef.#{environment} 1 #{Time.now.to_i}\n"
            socket = TCPSocket.open(config.server, config.port)
            socket.write(message)
          rescue Exception => e
            ui.error 'Graphite was unable to process the request.'
            ui.error e.to_s
          ensure
            socket.close unless socket.nil?
          end
        end
      end
    end
  end
end
