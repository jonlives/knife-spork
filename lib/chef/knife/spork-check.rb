require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkCheck < Chef::Knife
    include KnifeSpork::Runner

    banner 'knife spork check COOKBOOK'

    option :all,
      :short => '--a',
      :long => '--all',
      :description => 'Show all uploaded versions of the cookbook'

    def run
      self.config = Chef::Config.merge!(config)

      if name_args.empty?
        ui.fatal 'You must specify a cookbook name!'
        show_usage
        exit(1)
      end

      begin
        @cookbook = load_cookbook(name_args.first)
      rescue Chef::Exceptions::CookbookNotFoundInRepo => e
        ui.error "#{name_args.first} does not exist locally in your cookbook path(s), Exiting."
        exit(1)
      end
      
      run_plugins(:before_check)
      check
      run_plugins(:after_check)
    end

    private
    def check
      ui.msg "Checking versions for cookbook #{@cookbook.name}..."
      ui.msg ""
      ui.msg "Local Version:"
      ui.msg "  #{local_version}"
      ui.msg ""
      ui.msg "Remote Versions: (* indicates frozen)"
      remote_versions.each do |remote_version|
        if frozen?(remote_version)
          ui.msg " *#{remote_version}"
        else
          ui.msg "  #{remote_version}"
        end
      end
      ui.msg ""

      remote_versions.each do |remote_version|
        if remote_version == local_version
          if frozen?(remote_version)
            ui.warn "Your local version (#{local_version}) is frozen on the remote server. You'll need to bump before you can upload."
          else
            ui.error "The version #{local_version} exists on the server and is not frozen. Uploading will overwrite!"
          end

          return
        end
      end

      ui.msg 'Everything looks good!'
    end

    def local_version
      @cookbook.version
    end

    def remote_versions
      @remote_versions ||= begin
        environment = config[:environment]
        api_endpoint = environment ? "environments/#{environment}/cookbooks/#{@cookbook.name}" : "cookbooks/#{@cookbook.name}"
        cookbooks = rest.get_rest(api_endpoint)

        versions = cookbooks[@cookbook.name.to_s]['versions']
        (config[:all] ? versions : versions[0..4]).collect{|v| v['version']}
      rescue Net::HTTPServerException => e
        ui.info "#{@cookbook.name} does not yet exist on the Chef Server!"
        return []
      end
    end

    def frozen?(version)
      @versions_cache ||= {}

      @versions_cache[version.to_sym] ||= begin
        environment = config[:environment]
        api_endpoint = environment ? "environments/#{environment}/cookbooks/#{@cookbook.name}" : "cookbooks/#{@cookbook.name}/#{version}"
        rest.get_rest(api_endpoint).to_hash['frozen?']
      end
    end
  end
end
