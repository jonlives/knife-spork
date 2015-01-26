require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Influxdb < Plugin
      name :influxdb
      hooks :after_upload

      def perform
        safe_require 'influxdb'
        conn = InfluxDB::Client.new(config.database, host: config.host, port: config.port, username: config.username, password: config.password, use_ssl: config.ssl)
        environments.each do |environment|
          begin
            data = {
              user: current_user,
              cookbook: cookbook.name,
              version: cookbook.version
            }
            conn.write_point(config.series, data)
          rescue Exception => e
            ui.error 'Could not write data to influxdb'
            ui.error e.to_s
          end
        end
      end
    end
  end
end
