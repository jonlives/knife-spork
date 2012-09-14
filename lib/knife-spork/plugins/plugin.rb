module KnifeSpork
  module Plugins
    class Plugin
      # This is the name of the plugin. It must correspond to the name in the yaml configuration
      # file in order to load this plugin. If an attribute is passed in, the name is set to that
      # given value. Otherwise, the name is returned.
      def self.name(name = nil)
        if name.nil?
          class_variable_get(:@@name)
        else
          class_variable_set(:@@name, name)
        end
      end

      # This is a convenience method for defining multiple hooks in a single call.
      def self.hooks(*the_hooks)
        [the_hooks].flatten.each{ |the_hook| hook(the_hook) }
      end

      # When defining a hook, we define a method on the instance that corresponds to that
      # hook. That will be fired when the hook is fired.
      def self.hook(the_hook)
        self.send(:define_method, the_hook.to_sym) do
          perform
        end
      end

      def initialize(options = {})
        @options = {
          :payload => {}
        }.merge(options)
      end

      def enabled?
        !config.nil?
      end

      private
      def config
          @options[:config].plugins.send(self.class.name.to_sym) unless @options[:config].nil? || @options[:config].plugins.nil?
      end

      def cookbooks
        @options[:cookbooks]
      end

      def environments
        @options[:environments]
      end

      def environment_diffs
        @options[:environment_diffs]
      end

      def environment_path
        @options[:environment_path]
      end
      
      def cookbook_path
        @options[:cookbook_path]
      end
      
      def ui
        @options[:ui]
      end

      def current_user
        (begin `git config user.name`.chomp; rescue nil; end || ENV['USERNAME'] || ENV['USER']).strip
      end

      # Wrapper method around require that attempts to include the associated file. If it does not exist
      # or cannot be loaded, an nice error is produced instead of blowing up.
      def safe_require(file)
        begin
          require file
        rescue LoadError
          raise "You are using a plugin for knife-spork that requires #{file}, but you have not installed it. Please either run \"gem install #{file}\", add #{file} to your Gemfile or remove the plugin from your configuration."
        end
      end
    end
  end
end
