require 'knife-spork/plugins/plugin'
require 'json'
require 'uri'

module KnifeSpork
  module Plugins
    class Eventinator < Plugin
      name :eventinator
      hooks :after_upload

      def perform
        event_data = {
          :tag => 'knife',
          :username => current_user,
          :status => "#{current_user} has uploaded and frozen #{cookbooks.collect{|c| "#{c.name}@#{c.version}"}.join(', ')}",
          :metadata => {
            :cookbook_name => cookbook.name,
            :cookbook_version => cookbook.version
          }.to_json
        }

        begin
          uri = URI.parse(config.url)
        rescue Exception => e
          ui.error 'Could not parse URI for Eventinator.'
          ui.error e.to_s
          return
        end

        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = config.read_timeout || 5

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(event_data)

        begin
          response = http.request(request)
          ui.error "Eventinator at #{config.url} did not receive a good response from the server" if response.code != '200'
        rescue Timeout::Error
          ui.error "Eventinator timed out connecting to #{config.url}. Is that URL accessible?"
        rescue Exception => e
          ui.error 'Eventinator error.'
          ui.error e.to_s
        end
      end
    end
  end
end
