require 'chef/knife'

module KnifeSpork
  class SporkDataBagEdit < Chef::Knife

    deps do
      require 'knife-spork/runner'
      require 'json'
      require 'chef/knife/data_bag_edit'
    end

    banner 'knife spork data bag edit BAG ITEM (options)'

    option :secret,
           :short => "-s SECRET",
           :long  => "--secret ",
           :description => "The secret key to use to encrypt data bag item values"

    option :secret_file,
           :long => "--secret-file SECRET_FILE",
           :description => "A file containing the secret key to use to encrypt data bag item values"

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if @name_args.length != 2
        ui.error "You must supply the data bag and an item to edit!"
        ui.error opt_parser
        exit 1
      end

      @object_name = @name_args.first
      @object_secondary_name = @name_args.last

      run_plugins(:before_databagedit)
      pre_databag = load_databag_item(@object_name, @object_secondary_name)
      databag_edit
      post_databag = load_databag_item(@object_name, @object_secondary_name)
      @object_difference = json_diff(pre_databag,post_databag).to_s
      run_plugins(:after_databagedit)
    end

    private
    def databag_edit
      dbe = Chef::Knife::DataBagEdit.new
      dbe.name_args = @name_args
      dbe.config[:editor] = config[:editor]
      dbe.config[:secret] = config[:secret]
      dbe.config[:secret_file] = config[:secret_file]
      dbe.run
    end
  end
end
