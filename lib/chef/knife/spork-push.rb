require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkPush < Chef::Knife
    include KnifeSpork::Runner

    TYPE_INDEX = { :major => 0, :minor => 1, :patch => 2, :manual => 3 }.freeze

    banner 'knife spork push COOKBOOK - push changes to github and submit a pull request'

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify at least a cookbook name")
        exit 1
      end

      @cookbook = load_cookbook(name_args.first)

      run_plugins(:before_push)
      push
      run_plugins(:after_push)
    end

    private
    def push; end

  end
end
