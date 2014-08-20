require 'chef/knife'

module KnifeSpork
  class SporkNodeRunListSet < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork node run_list set NODE ENTRIES (options)'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.size < 2
        ui.error "You must supply both a node name and a run list."
        show_usage
        exit 1
      end

      @object_name = @name_args.first

      @object_secondary_name = @name_args[1..-1].map do |entry|
        entry.split(',').map { |e| e.strip }
      end.flatten.to_s

      run_plugins(:before_noderunlistset)
      pre_node = load_node(@object_name)
      node_runlistset
      post_node = load_node(@object_name)
      @object_difference = json_diff(pre_node,post_node).to_s
      run_plugins(:after_noderunlistset)
    end

    private
    def node_runlistset
      nrla = Chef::Knife::NodeRunListSet.new
      nrla.name_args = @name_args
      nrla.config[:editor] = config[:editor]
      nrla.run
    end
  end
end
