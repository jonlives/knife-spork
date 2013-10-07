require 'chef/knife'
require 'knife-spork/runner'
require 'json'

module KnifeSpork
  class SporkDataBagCreate < Chef::Knife
    include KnifeSpork::Runner

    deps do
      require 'chef/knife/data_bag_create'
    end

    banner 'knife data bag create BAG [ITEM] (options)'

    option :secret,
           :short => "-s SECRET",
           :long  => "--secret ",
           :description => "The secret key to use to encrypt data bag item values"

    option :secret_file,
           :long => "--secret-file SECRET_FILE",
           :description => "A file containing the secret key to use to encrypt data bag item values"

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.nil?
        ui.error "You must specify a data bag name"
        ui.error opt_parser
        exit 1
      end

      @object_name = @name_args.first

      run_plugins(:before_databagcreate)
      pre_databag = {}
      databag_create
      post_databag = load_databag(@object_name)
      @object_difference = json_diff(pre_databag,post_databag).to_s
      run_plugins(:after_databagcreate)
    end

    private
    def databag_create
      dbc = Chef::Knife::DataBagCreate.new
      dbc.name_args = @name_args
      dbc.config[:editor] = config[:editor]
      dbc.config[:secret] = config[:secret]
      dbc.config[:secret_file] = config[:secret_file]
      dbc.run
    end
  end
end
