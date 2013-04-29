require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Grove < Plugin
      name :grove

      def perform; end

      def after_upload
        grove <<-EOH
#{current_user} froze the following cookbooks on Chef Server: #{cookbooks.collect{|c| "#{c.name}@#{c.version}"}.join(', ')}
        EOH
      end

      def after_promote_remote
        grove <<-EOH
#{current_user} promoted #{cookbooks.collect{|c| "#{c.name}@#{c.version}"}.join(', ')} on #{environments.collect{|e| "#{e.name}"}.join(', ')}
        EOH
      end

      private
      def grove(message)
        safe_require 'rest_client'

        config.tokens.each do |token|
          # Grove can't handle multi-line messages, so let's split by line
          message.split("\n").flatten.delete_if(&:empty?).each do |line|
            RestClient.post "https://grove.io/api/notice/#{token}/",
                            :message => line,
                            :service => 'knife-spork'
          end
        end
      end

      def tokens
        Array(config.token || config.tokens)
      end
    end
  end
end
