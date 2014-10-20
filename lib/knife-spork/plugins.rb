module KnifeSpork
  module Plugins
    # Load each of the drop-in plugins
    Dir[File.expand_path('../plugins/**/*.rb', __FILE__)].each { |f| require f }

    def self.run(options = {})
      hook = options[:hook].to_sym

      #Load each of the drop-in plugins specified in the custom plugin path
      if (options[:config][:custom_plugin_path] !=nil)
        Dir[File.expand_path("#{options[:config][:custom_plugin_path]}/*.rb")].each { |f| require f }
      end

      klasses.each do |klass|
        plugin = klass.new(options)
        plugin.send(hook) if plugin.respond_to?(hook) && plugin.enabled?
      end
    end

    # Get and return a list of all subclasses (plugins) that are not the base plugin
    def self.klasses
      @@klasses ||= self.constants.collect do |c|
        self.const_get(c) if self.const_get(c).is_a?(Class) && self.const_get(c) != KnifeSpork::Plugins::Plugin
      end.compact
    end
  end
end
