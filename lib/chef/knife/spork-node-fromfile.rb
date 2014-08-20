require 'chef/knife'

module KnifeSpork
  class SporkNodeFromFile < Chef::Knife

    deps do
      require 'knife-spork/runner'
    end

    banner 'knife spork node from file FILE (options)'


    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify a filename")
        exit 1
      end

      @object_name = JSON.parse(File.read(@name_args.first))["name"]
      ui.info @object_name

      run_plugins(:before_nodefromfile)
      begin
        pre_node = load_node(@object_name.gsub(".json",""))
      rescue
        pre_node = {}
      end
      node_fromfile
      post_node = load_node(@object_name.gsub(".json",""))
      @object_difference = json_diff(pre_node,post_node).to_s
      run_plugins(:after_nodefromfile)
    end

    private
    def node_fromfile
      nff = Chef::Knife::NodeFromFile.new
      nff.name_args = @name_args
      nff.config[:editor] = config[:editor]
      nff.run
    end
  end
end
