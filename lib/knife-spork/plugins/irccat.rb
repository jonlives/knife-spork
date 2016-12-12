require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Irccat < Plugin
      name :irccat

      TEMPLATES = {
        :upload  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} uploaded #TEAL%{cookbooks}#NORMAL',
        :delete => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} deleted the following cookbooks: #TEAL%{misc_output}#NORMAL',
        :promote => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} promoted #TEAL%{cookbooks}#NORMAL to %{environment} %{gist}',
        :environmentfromfile  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} uploaded environment #TEAL%{object_name}#NORMAL %{gist}',
        :environmentedit  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} edited environment #TEAL%{object_name}#NORMAL %{gist}',
        :environmentcreate  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} created environment #TEAL%{object_name}#NORMAL %{gist}',
        :environmentdelete  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} deleted environment #TEAL%{object_name}#NORMAL %{gist}',
        :rolefromfile  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} uploaded role #TEAL%{object_name}#NORMAL %{gist}',
        :roleedit  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} edited role #TEAL%{object_name}#NORMAL %{gist}',
        :rolecreate  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} created role #TEAL%{object_name}#NORMAL %{gist}',
        :roledelete  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} deleted role #TEAL%{object_name}#NORMAL %{gist}',
        :databagedit  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} edited data bag item #TEAL%{object_name}:%{object_secondary_name}#NORMAL %{gist}',
        :databagdelete  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} deleted data bag #TEAL%{object_name}#NORMAL %{gist}',
        :databagitemdelete  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} deleted data bag item #TEAL%{object_name}:%{object_secondary_name}#NORMAL %{gist}',
        :databagcreate  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} created data bag #TEAL%{object_name}#NORMAL %{gist}',
        :databagfromfile  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} uploaded data bag item #TEAL%{object_name}:%{object_secondary_name}#NORMAL %{gist}',
        :nodeedit  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} edited node #TEAL%{object_name}#NORMAL %{gist}',
        :nodedelete  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} deleted node #TEAL%{object_name}#NORMAL %{gist}',
        :nodecreate  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} created node #TEAL%{object_name}#NORMAL %{gist}',
        :nodefromfile  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} uploaded node #TEAL%{object_name}#NORMAL %{gist}',
        :noderunlistadd  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} added run_list items to #TEAL%{object_name}: %{object_secondary_name}#NORMAL %{gist}',
        :noderunlistremove  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} removed run_list items from #TEAL%{object_name}: %{object_secondary_name}#NORMAL %{gist}',
        :noderunlistset  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} set the  run_list for #TEAL%{object_name} to %{object_secondary_name}#NORMAL %{gist}'
      }

      def perform; end

      def after_upload
        irccat(template(:upload) % {
          :organization => organization,
          :current_user => current_user,
          :cookbooks    => cookbooks.collect { |c| "#{c.name}@#{c.version}" }.join(", ")
        })
      end

      def after_delete
        irccat(template(:delete) % {
          :organization => organization,
          :current_user => current_user,
          :misc_output => misc_output 
        })
      end

      def after_promote_remote
        environments.each do |environment|
          diff = environment_diffs[environment.name]
          env_gist = env_gist(environment, diff) if config.gist
          display_gist(env_gist) if env_gist
          irccat(template(:promote) % {
            :organization => organization,
            :current_user => current_user,
            :cookbooks    => cookbooks.collect{ |c| "#{c.name}@#{c.version}" }.join(", "),
            :environment  => environment.name,
            :gist         => env_gist
          })
        end
      end

      def after_environmentfromfile
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(environment_gist) if environment_gist
        irccat(template(:environmentfromfile) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => environment_gist
        })
      end

      def after_environmentedit
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(environment_gist) if environment_gist
        irccat(template(:environmentedit) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => environment_gist
        })
      end

      def after_environmentcreate
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(environment_gist) if environment_gist
        irccat(template(:environmentcreate) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => environment_gist
        })
      end

      def after_environmentdelete
        environment_gist = object_gist("environment", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(environment_gist) if environment_gist
        irccat(template(:environmentdelete) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => environment_gist
        })
      end

      def after_rolefromfile
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(role_gist) if role_gist
        irccat(template(:rolefromfile) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => role_gist
        })
      end

      def after_roleedit
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(role_gist) if role_gist
        irccat(template(:roleedit) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => role_gist
        })
      end

      def after_rolecreate
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(role_gist) if role_gist
        irccat(template(:rolecreate) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => role_gist
        })
      end

      def after_roledelete
        role_gist = object_gist("role", object_name, object_difference) if config.gist  and !object_difference.empty?
        display_gist(role_gist) if role_gist
        irccat(template(:roledelete) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => role_gist
        })
      end

      def after_databagedit
        databag_gist = object_gist("databag item", "#{object_name}:#{object_secondary_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(databag_gist) if databag_gist
        irccat(template(:databagedit) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :object_secondary_name    => object_secondary_name,
            :gist => databag_gist
        })
      end

      def after_databagdelete
        databag_gist = object_gist("databag item", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(databag_gist) if databag_gist
        irccat(template(:databagdelete) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => databag_gist
        })
      end

      def after_databagitemdelete
        databag_gist = object_gist("databag item", "#{object_name}:#{object_secondary_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(databag_gist) if databag_gist
        irccat(template(:databagitemdelete) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :object_secondary_name    => object_secondary_name,
            :gist => databag_gist
        })
      end

      def after_databagcreate
        databag_gist = object_gist("databag", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(databag_gist) if databag_gist
        irccat(template(:databagcreate) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => databag_gist
        })
      end

      def after_databagfromfile
        databag_gist = object_gist("databag", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(databag_gist) if databag_gist
        irccat(template(:databagfromfile) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :object_secondary_name    => object_secondary_name,
            :gist => databag_gist
        })
      end

      def after_nodeedit
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(node_gist) if node_gist
        irccat(template(:nodeedit) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => node_gist
        })
      end

      def after_nodedelete
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(node_gist) if node_gist
        irccat(template(:nodedelete) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => node_gist
        })
      end

      def after_nodecreate
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(node_gist) if node_gist
        irccat(template(:nodecreate) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => node_gist
        })
      end

      def after_nodefromfile
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(node_gist) if node_gist
        irccat(template(:nodefromfile) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :gist => node_gist
        })
      end

      def after_noderunlistadd
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(node_gist) if node_gist
        irccat(template(:noderunlistadd) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :object_secondary_name    => object_secondary_name,
            :gist => node_gist
        })
      end

      def after_noderunlistremove
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(node_gist) if node_gist
        irccat(template(:noderunlistremove) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :object_secondary_name    => object_secondary_name,
            :gist => node_gist
        })
      end

      def after_noderunlistset
        node_gist = object_gist("node", "#{object_name}", object_difference) if config.gist  and !object_difference.empty?
        display_gist(node_gist) if node_gist
        irccat(template(:noderunlistset) % {
            :organization => organization,
            :current_user => current_user,
            :object_name    => object_name,
            :object_secondary_name    => object_secondary_name,
            :gist => node_gist
        })
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

      def env_gist(environment, diff)
        msg = "Environment #{environment} uploaded at #{Time.now.getutc} by #{current_user}\n\nConstraints updated on server in this version:\n\n#{diff.collect { |k, v| "#{k}: #{v}\n" }.join}"
        %x[ echo "#{msg}" | #{config.gist}]
      end

      def display_gist(gist)
        ui.info "Gist generated at #{gist}"
      end

      def object_gist(object_type, object_name, object_diff)
        msg = "#{object_type.capitalize} #{object_name} changed at #{Time.now.getutc} by #{current_user}\n\nDiff is as follows:\n\n#{object_diff}"
        %x[ echo "#{msg}" | #{config.gist}]
      end

      def channels
        [ config.channel || config.channels ].flatten
      end

      def template(name)
        (config.template && config.template[name]) || TEMPLATES[name]
      end
    end
  end
end
