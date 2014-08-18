require 'chef/knife'

module KnifeSpork
  class SporkDataBagDelete < Chef::Knife

    deps do
      require 'knife-spork/runner'
      require 'json'
      require 'chef/knife/data_bag_delete'
    end

    banner 'knife spork data bag delete BAG [ITEM] (options)'


    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.length == 2
        @object_name = @name_args.first
        @object_secondary_name = @name_args.last
        run_plugins(:before_databagitemdelete)
        pre_databag = load_databag_item(@object_name,@object_secondary_name)
        databag_delete
        post_databag = {}
        @object_difference = json_diff(pre_databag,post_databag).to_s
        run_plugins(:after_databagitemdelete)
      elsif @name_args.length == 1
        @object_name = @name_args.first
        run_plugins(:before_databagdelete)
        pre_databag = load_databag(@object_name)
        databag_delete
        post_databag =  {}
        @object_difference = json_diff(pre_databag,post_databag).to_s
        run_plugins(:after_databagdelete)
      else
        show_usage
        ui.fatal("You must specify at least a data bag name")
        exit 1
      end
    end

    private
    def databag_delete
      dbd = Chef::Knife::DataBagDelete.new
      dbd.name_args = @name_args
      dbd.config[:editor] = config[:editor]
      dbd.run
    end
  end
end
