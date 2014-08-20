require 'chef/knife'

module KnifeSpork
  class SporkNodeRunListRemove < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork node run_list add [NODE] [ENTRY[,ENTRY]] (options)'

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a node name and item to remove")
        exit 1
      end

      @object_name = @name_args.first

      @object_secondary_name = @name_args[1..-1].map do |entry|
        entry.split(',').map { |e| e.strip }
      end.flatten.to_s

      run_plugins(:before_noderunlistremove)
      pre_node = load_node(@object_name)
      node_runlistremove
      post_node = load_node(@object_name)
      @object_difference = json_diff(pre_node,post_node).to_s
      run_plugins(:after_noderunlistremove)
    end

    private
    def node_runlistremove
      nrla = Chef::Knife::NodeRunListRemove.new
      nrla.name_args = @name_args
      nrla.config[:editor] = config[:editor]
      nrla.run
    end
  end
end
