require 'knife-spork/plugins/plugin'
require 'json'
require 'uri'

module KnifeSpork
  module Plugins
    class Eventinator < Plugin
      name :eventinator

      def perform; end

      def after_upload
        cookbooks.each do |cookbook|
          event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} uploaded and froze #{cookbook.name}@#{cookbook.version}",
            :metadata => {
              :cookbook_name => cookbook.name,
              :cookbook_version => cookbook.version
            }.to_json
          }
          eventinate(event_data)
        end
      end

      def after_delete
        event_data = {
          :tag => 'knife',
          :username => current_user,
          :status => "#{organization}#{current_user} deleted the following cookbooks: #{misc_output}",
          :metadata => {
            :deleted_cookbooks => misc_output
          }.to_json
        }
        eventinate(event_data)
      end

      def after_promote_remote
        environments.each do |environment|
          cookbooks.each do |cookbook|
            event_data = {
              :tag => 'knife',
              :username => current_user,
              :status => "#{organization}#{current_user} promoted #{cookbook.name}(#{cookbook.version}) to #{environment.name}",
              :metadata => {
                :cookbook_name => cookbook.name,
                :cookbook_version => cookbook.version
              }.to_json
            }
            eventinate(event_data)
          end
        end
      end

      def after_environmentfromfile
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} uploaded environment #{object_name}",
            :metadata => {
                :environment_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_environmentedit
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} edited environment #{object_name}",
            :metadata => {
                :environment_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_environmentcreate
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} created environment #{object_name}",
            :metadata => {
                :environment_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_environmentdelete
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} deleted environment #{object_name}",
            :metadata => {
                :environment_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_rolefromfile
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} uploaded role #{object_name}",
            :metadata => {
                :role_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_roleedit
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} edited role #{object_name}",
            :metadata => {
                :role_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_rolecreate
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} created role #{object_name}",
            :metadata => {
                :role_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_roledelete
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} deleted role #{object_name}",
            :metadata => {
                :role_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_databagedit
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} edited data bag item #{object_name}:#{object_secondary_name}",
            :metadata => {
                :databag_name => object_name,
                :databag_item => object_secondary_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_databagcreate
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} created data bag #{object_name}",
            :metadata => {
                :databag_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_databagdelete
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} deleted data bag item #{object_name}",
            :metadata => {
                :databag_name => object_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_databagitemdelete
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} deleted data bag item #{object_name}:#{object_secondary_name}",
            :metadata => {
                :databag_name => object_name,
                :databag_item => object_secondary_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_databagfromfile
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} uploaded data bag item #{object_name}:#{object_secondary_name}",
            :metadata => {
                :databag_name => object_name,
                :databag_item => object_secondary_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_nodeedit
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} edited node #{object_name}",
            :metadata => {
                :node_name => object_name
            }.to_json
        }
        eventinate(event_data)
      end

      def after_nodedelete
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} deleted node #{object_name}",
            :metadata => {
                :node_name => object_name
            }.to_json
        }
        eventinate(event_data)
      end

      def after_nodecreate
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} created node #{object_name}",
            :metadata => {
                :node_name => object_name
            }.to_json
        }
        eventinate(event_data)
      end

      def after_nodefromfile
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} uploaded node #{object_name}",
            :metadata => {
                :node_name => object_name
            }.to_json
        }
        eventinate(event_data)
      end

      def after_noderunlistadd
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} added run_list items to #{object_name}: #{object_secondary_name}",
            :metadata => {
                :node_name => object_name,
                :run_list_items => object_secondary_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_noderunlistremove
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} removed run_list items from #{object_name}: #{object_secondary_name}",
            :metadata => {
                :node_name => object_name,
                :run_list_items => object_secondary_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def after_noderunlistset
        event_data = {
            :tag => 'knife',
            :username => current_user,
            :status => "#{organization}#{current_user} set the run_list for #{object_name} to #{object_secondary_name}",
            :metadata => {
                :node_name => object_name,
                :run_list_items => object_secondary_name,
            }.to_json
        }
        eventinate(event_data)
      end

      def eventinate(event_data)
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
