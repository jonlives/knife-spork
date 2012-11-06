require 'chef/knife'
require 'chef/knife/cookbook_create'
require 'chef/cookbook_version'
require 'chef/exceptions'
require 'knife-spork/runner'

module KnifeSpork
  class SporkCreate< Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork create [COOKBOOK] (options)'

    option :cookbook_path,
      :short => '-o PATH:PATH',
      :long => '--cookbook-path PATH:PATH',
      :description => 'A colon-separated path to look for cookbooks in',
      :proc => lambda { |o| o.split(':') }

    def run
      self.config = Chef::Config.merge!(config)
      config[:cookbook_path] ||= Chef::Config[:cookbook_path]

      if @name_args.empty?
        show_usage
        ui.error("You must specify a cookbook name")
        exit 1
      end

      cookbook_name = @name_args.first
      @cookbook = ::Chef::CookbookVersion.new(cookbook_name)
      @cookbook.root_dir = "#{cookbook_path}/#{cookbook_name}"

      run_plugins(:before_create)
      create
      run_plugins(:after_create)
    end

    private

    def create
      create = ::Chef::Knife::CookbookCreate.new
      create.name_args = @name_args
      create.run
    end

    def default_cookbook_path_empty?
      Chef::Config[:cookbook_path].nil? || Chef::Config[:cookbook_path].empty?
    end

    def parameter_empty?(parameter)
      parameter.nil? || parameter.empty?
    end

  end
end
