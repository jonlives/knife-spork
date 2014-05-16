require 'chef/knife'

module KnifeSpork
  class SporkInfo < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork info'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      run_plugins(:before_info)
      info
      run_plugins(:after_info)
    end

    private
    def info
      ui.msg "Config Hash:"
      ui.msg "#{spork_config.to_hash}"
      ui.msg ""
      ui.msg "Plugins:"
      KnifeSpork::Plugins.klasses.each do |klass|
        plugin = klass.new(:config => spork_config)
        ui.msg "#{klass}: #{plugin.enabled? ? 'enabled' : 'disabled'}"
      end
    end
  end
end
