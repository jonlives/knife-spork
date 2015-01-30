require 'chef/knife'

module KnifeSpork
  class SporkOmni < Chef::Knife

    deps do
      require 'knife-spork/runner'
      begin
        require 'berkshelf'
      rescue LoadError; end
    end

    banner 'knife spork omni COOKBOOK (options)'

    option :cookbook_path,
           :short => '-o PATH:PATH',
           :long => '--cookbook-path PATH:PATH',
           :description => 'A colon-separated path to look for cookbooks in',
           :proc => lambda { |o| o.split(':') }

    option :depends,
           :short => '-D',
           :long => '--include-dependencies',
           :description => 'Also upload cookbook dependencies during the upload step'

    option :bump_level,
           :short => '-l',
           :long  => '--bump-level [major|minor|patch]',
           :description => 'Version level to bump the cookbook (defaults to patch)',
           :default => nil

    option :omni_environment,
           :short => '-e',
           :long  => '--environment ENVIRONMENT',
           :description => 'Environment to promote the cookbook to',
           :default => nil

    option :remote,
           :long  => '--remote',
           :description => 'Make omni finish with promote --remote instead of a local promote',
           :default => nil

    option :berksfile,
           :short => '-b',
           :long => '--berksfile BERKSFILE',
           :description => 'Path to a Berksfile to operate from',
           :default => nil,
           :proc => lambda { |o| o || File.join(Dir.pwd, ::Berkshelf::DEFAULT_FILENAME) }

    def run
      self.class.send(:include, KnifeSpork::Runner)
      self.config = Chef::Config.merge!(config)

      if name_args.empty?
        ui.fatal 'You must specify a cookbook name!'
        show_usage
        exit(1)
      end

      # Temporary fix for #138 to allow Berkshelf functionality
      # to be bypassed until #85 has been completed and Berkshelf 3 support added
      unload_berkshelf_if_specified

      cookbook = name_args.first

      run_plugins(:before_omni)
      omni(cookbook)
      run_plugins(:after_omni)
    end

    private

    def bump(cookbook)
      ui.msg "OMNI: Bumping #{cookbook}"
      bump = SporkBump.new
      bump.name_args = [cookbook,config[:bump_level]]
      bump.run
    end

    def upload(cookbook)
      ui.msg "OMNI: Uploading #{cookbook}"
      upload = SporkUpload.new
      upload.name_args = [cookbook]
      upload.config[:cookbook_path] = config[:cookbook_path]
      upload.config[:depends] = config[:depends]
      upload.run
    end

    def promote(cookbook)
      ui.msg "OMNI: Promoting #{cookbook}"
      promote = SporkPromote.new
      if config[:omni_environment]
        promote.name_args = [config[:omni_environment],cookbook]
      else
        promote.name_args = [cookbook]
      end
      promote.config[:remote] = config[:remote]
      if defined?(::Berkshelf)
        promote.config[:berksfile] = config[:berksfile]
      end
      promote.run
    end

    def omni(cookbook)
      bump(cookbook)
      ui.msg ""
      upload(cookbook)
      ui.msg ""
      promote(cookbook)
    end
  end
end
