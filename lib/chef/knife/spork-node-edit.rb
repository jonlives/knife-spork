require 'chef/knife'

module KnifeSpork
  class SporkNodeEdit < Chef::Knife

    deps do
      require 'chef/knife/core/node_editor'
      require 'knife-spork/runner'
    end

    banner 'knife spork node edit NODE (options)'

    option :all_attributes,
           :short => "-a",
           :long => "--all",
           :boolean => true,
           :description => "Display all attributes when editing"

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a node name")
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_nodeedit)
      pre_node = load_node(@object_name)
      node_edit
      post_node = load_node(@object_name)
      @object_difference = json_diff(pre_node,post_node).to_s
      run_plugins(:after_nodeedit)
    end

    private
    def node_edit
      ne = Chef::Knife::NodeEdit.new
      ne.name_args = @name_args
      ne.config[:editor] = config[:editor]
      ne.config[:all] = config[:all]
      ne.run
    end
  end
end
