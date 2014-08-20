require 'chef/knife'

module KnifeSpork
  class SporkNodeRunListAdd < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork node run_list add [NODE] [ENTRY[,ENTRY]] (options)'


    option :after,
           :short => "-a ITEM",
           :long  => "--after ITEM",
           :description => "Place the ENTRY in the run list after ITEM"

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a node name and item to add")
        exit 1
      end

      @object_name = @name_args.first

      @object_secondary_name = @name_args[1..-1].map do |entry|
        entry.split(',').map { |e| e.strip }
      end.flatten.to_s

      run_plugins(:before_noderunlistadd)
      pre_node = load_node(@object_name)
      node_runlistadd
      post_node = load_node(@object_name)
      @object_difference = json_diff(pre_node,post_node).to_s
      run_plugins(:after_noderunlistadd)
    end

    private
    def node_runlistadd
      nrla = Chef::Knife::NodeRunListAdd.new
      nrla.name_args = @name_args
      nrla.config[:editor] = config[:editor]
      nrla.config[:after] = config[:after]
      nrla.run
    end
  end
end
