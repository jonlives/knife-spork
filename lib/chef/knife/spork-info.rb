require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkInfo < Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork info'

    def run
      self.config = Chef::Config.merge!(config)

      run_plugins(:before_info)
      info
      run_plugins(:after_info)
    end

    private
    def info
			ui.info "Config Hash:"
			ui.info "#{spork_config.to_hash}"
			ui.info ""
			ui.info "Plugins:"
			KnifeSpork::Plugins.klasses.each do |klass|
				plugin = klass.new(:config => spork_config)
        ui.info "#{klass}: #{plugin.enabled? ? 'enabled' : 'disabled'}"
      end
    end
  end
end
