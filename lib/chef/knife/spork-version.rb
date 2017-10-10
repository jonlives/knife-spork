require 'chef/knife'
require 'knife-spork/version'

module KnifeSpork
  class SporkVersion < Chef::Knife
    banner 'knife spork version'

    def run
      ui.info KnifeSpork::Version::VERSION
    end
  end
end
