require 'chef/knife'

module KnifeSpork
  class SporkNodeCreate < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork node create NODE (options)'


    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a node name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_nodecreate)
      pre_node = {}
      node_create
      post_node = load_node(@object_name)
      @object_difference = json_diff(pre_node,post_node).to_s
      run_plugins(:after_nodecreate)
    end

    private
    def node_create
      ne = Chef::Knife::NodeCreate.new
      ne.name_args = @name_args
      ne.config[:editor] = config[:editor]
      ne.run
    end
  end
end
