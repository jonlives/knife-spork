require 'chef/knife'

module KnifeSpork
  class SporkNodeDelete < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork node delete NODE (options)'


    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a node name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_nodedelete)
      pre_node = load_node(@object_name)
      node_delete
      post_node = {}
      @object_difference = json_diff(pre_node,post_node).to_s
      run_plugins(:after_nodedelete)
    end

    private
    def node_delete
      ne = Chef::Knife::NodeDelete.new
      ne.name_args = @name_args
      ne.config[:editor] = config[:editor]
      ne.run
    end
  end
end
