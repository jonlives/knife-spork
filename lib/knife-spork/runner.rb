require 'app_conf'
require 'diffy'
require 'json'

require 'chef/cookbook_loader'
require 'chef/environment'
require 'chef/data_bag_item'
require 'chef/knife/core/object_loader'
require 'knife-spork/plugins'

module KnifeSpork
  module Runner
    module ClassMethods; end

    module InstanceMethods
      def spork_config
        return @spork_config unless @spork_config.nil?

        @spork_config = AppConf.new
        load_paths = [ File.expand_path("#{cookbook_path.gsub('cookbooks','')}/config/spork-config.yml"), File.expand_path('config/spork-config.yml'), '/etc/spork-config.yml', File.expand_path('~/.chef/spork-config.yml'), File.expand_path("#{cookbook_path.gsub('cookbooks','')}/.chef/spork-config.yml") ]
        load_paths.each do |load_path|
          if File.exists?(load_path)
            @spork_config.load(load_path)
          end
        end

        @spork_config
      end

      def run_plugins(hook)
        cookbooks = [ @cookbooks || @cookbook ].flatten.compact.collect{|cookbook| cookbook.is_a?(::Chef::CookbookVersion) ? cookbook : load_cookbook(cookbook)}.sort{|a,b| a.name.to_s <=> b.name.to_s}

        # Affects promote only:
        # Set loaded cookbook version if the -v or --version parameter was specified
        # Otherwise the version on disk, often more recent will be used.
        # We know cookbooks will only contain one cookbook in the case of promote.
        cookbooks.map{|c|c.version = config[:version]} if config[:version]

        environments = [ @environments || @environment ].flatten.compact.collect{|environment| environment.is_a?(::Chef::Environment) ? environment : load_environment_from_file(environment)}.sort{|a,b| a.name.to_s <=> b.name.to_s}
        environment_diffs = @environment_diffs
        
        KnifeSpork::Plugins.run(
          :config => spork_config,
          :hook => hook.to_sym,
          :cookbooks => cookbooks,
          :environments => environments,
          :environment_diffs => environment_diffs,
          :environment_path => environment_path,
          :cookbook_path => cookbook_path,
          :object_name => @object_name,
          :object_secondary_name => @object_secondary_name,
          :object_difference => @object_difference,
          :misc_output => @misc_output,
          :ui => ui
        )
      end

      def load_environments_and_cookbook
        ensure_environment_and_cookbook_provided!
       
        if @name_args.size == 2
          environments = @name_args[0].split(",").map{ |env| load_specified_environment_group(env) }
          [ environments.flatten, @name_args[1] ]
        elsif @name_args.size == 1
          [ [default_environments].flatten, @name_args[0] ]
        end
      end

      def verify_and_load_environments
        ensure_environment_provided!

        if @name_args.size == 0
          default_environments
        elsif @name_args.size == 1
          [@name_args[0]]
        end
      end

      def load_specified_environment_group(name)
        if !spork_config.environment_groups.nil? && spork_config.environment_groups.keys.include?(name)
          spork_config.environment_groups[name]
        else
          [name]
        end
      end

      def ensure_environment_and_cookbook_provided!
        if default_environments.empty? && @name_args.size < 2
          ui.error('You must specify an environment or environment group and a cookbook name')
          exit(1)
        end
      end

      def ensure_environment_provided!
        if default_environments.empty? && @name_args.size < 1
          ui.error('You must specify an environment or configure default environments.')
          exit(1)
        end
      end

      def default_environments
        [ spork_config.default_environment || spork_config.default_environments ].flatten.compact
      end

      def pretty_print_json(json)
        options = spork_config[:json_options] || {}
        # generate requires a hash where the keys are symbols
        options = Hash[ options.to_hash.map {|(k,v)| [k.to_sym,v] }] unless options == {}
        JSON.pretty_generate(json, options.to_hash)
      end

      def save_environment_changes(environment, json)
        if @config[:environment_path]
          environments_path = @config[:environment_path]
        elsif spork_config[:environment_path]
          environments_path = spork_config[:environment_path]
        else
          split_cb_path = cookbook_path.split("/")
          environments_path = (split_cb_path[0..-2] << split_cb_path[-1].gsub("cookbooks","environments")).join("/")
        end

        environment_path = File.expand_path( File.join(environments_path, "#{environment}.json") )

        File.open(environment_path, 'w'){ |f| f.puts(json) }
      end

      def valid_version?(version)
        version_keys = version.split('.')
        return false unless version_keys.size == 3 && version_keys.any?{ |k| begin Float(k); rescue false; else true; end }
        true
      end

      def validate_version!(version)
        if version && !valid_version?(version)
          ui.error("#{version} is not a valid version!")
          exit(1)
        end
      end

      def environment_loader
        @environment_loader ||= Chef::Knife::Core::ObjectLoader.new(::Chef::Environment, ui)
      end

      def role_loader
        @role_loader ||= Chef::Knife::Core::ObjectLoader.new(::Chef::Role, ui)
      end

      # It's not feasible to try and "guess" which cookbook path to use, so we will
      # always just use the first one in the path.
      def cookbook_path
        ensure_cookbook_path!
        [config[:cookbook_path] ||= ::Chef::Config.cookbook_path].flatten[0]
      end

      def environment_path
        if spork_config[:environment_path]
          if spork_config[:environment_path].kind_of?(Array)
            spork_config[:environment_path].first
          else
            spork_config[:environment_path]
          end
        elsif Chef::Config.environment_path && Chef::Config.environment_path.kind_of?(Array)
          Chef::Config.environment_path.first
        elsif Chef::Config.environment_path && Chef::Config.environment_path.kind_of?(String)
          Chef::Config.environment_path
        else
          cookbook_path.gsub("/cookbooks","/environments")
        end
      end

      def role_path
        spork_config[:role_path] || cookbook_path.gsub("/cookbooks","/roles")
      end

      def all_cookbooks
        ::Chef::CookbookLoader.new(::Chef::Config.cookbook_path)
      end

      def load_cookbook(name)
        return name if name.is_a?(Chef::CookbookVersion)

        cookbook = load_from_chef(name) || load_from_berkshelf(name) || load_from_librarian(name)

        cookbook || raise(Chef::Exceptions::CookbookNotFound,
          "Could not find cookbook '#{name}' in any of the sources!")
      end

      def load_from_chef(name)
        all_cookbooks[name]
      rescue Chef::Exceptions::CookbookNotFound,
             Chef::Exceptions::CookbookNotFoundInRepo
        nil
      end

      def load_from_berkshelf(name)
        return unless defined?(::Berkshelf)
        return unless self.config[:berksfile] && ::File.exist?(self.config[:berksfile])
        berksfile = ::Berkshelf::Berksfile.from_file(self.config[:berksfile])
        lockfile = ::Berkshelf::Lockfile.new(berksfile)

        raise Berkshelf::BerkshelfError, "LockFileNotFound" unless File.exists?(lockfile.filepath)

        cookbook = Berkshelf.ui.mute {
          self.config[:skip_dependencies] ||= false
          berksfile.resolve(lockfile.find(name), {skip_dependencies: self.config[:skip_dependencies]})[:solution].first
        }

        #convert Berkshelf::CachedCookbook to Chef::CookbookVersion
        ::Chef::CookbookLoader.new(File.dirname(cookbook.path))[name]

      end

      # @todo #opensource
      def load_from_librarian(name)
        # Your code here :)
        nil
      end

      def load_cookbooks(cookbook_names)
        cookbook_names = [cookbook_names].flatten
        cookbook_names.collect{ |cookbook_name| load_cookbook(cookbook_name) }
      end


      def load_role_from_file(role_name)
        role_loader.object_from_file("#{role_path}/#{role_name}.json")
      end

      def load_role(role_name)
        Chef::Role.load(role_name)
      end

      def load_node(node)
        Chef::Node.load(node)
      end

      def load_databag(bag)
        Chef::DataBag.load(bag)
      end

      def load_databag_item(bag, item_name)
        Chef::DataBagItem.load(bag, item_name)
      end

      def load_environment(environment_name)
        Chef::Environment.load(environment_name)
      end

      def load_environment_from_file(environment_name)
        begin
          environment_loader.object_from_file("#{environment_path}/#{environment_name}.json")
        rescue FFI_Yajl::ParseError => e
          raise "#{environment_name} environment file has syntactically incorrect json.\n #{e.to_s}" 
        end
      end

      def load_remote_environment(environment_name)
        begin
          Chef::Environment.load(environment_name)
        rescue Net::HTTPServerException => e
          ui.error "Could not load #{environment_name} from Chef Server. You must upload the environment manually the first time."
          exit(1)
        end
      end

      def environment_diff(local_environment, remote_environment)
        local_environment_versions = local_environment.to_hash['cookbook_versions']
        remote_environment_versions = remote_environment.to_hash['cookbook_versions']
        hash_diff remote_environment_versions, local_environment_versions
      end

      def json_diff(a, b)
        pre_json =  JSON.parse(a.respond_to?(:to_json) ? a.to_json : a)
        post_json =  JSON.parse(b.respond_to?(:to_json) ? b.to_json : b)
        diff = Diffy::Diff.new(JSON.pretty_generate(pre_json), JSON.pretty_generate(post_json), :diff=>"-U 3")
        if spork_config.stdout_diffs
          ui.info "Diff:"
          ui.info diff.to_s(:color)
        end
        return diff.to_s.gsub(/[()]/, '\\\\\0')
      end

      def hash_diff(hash, other)
        hash.keys.inject({}) do |memo, key|
          unless hash[key] == other[key]
            memo[key] = "#{hash[key]} changed to #{other[key]}"
          end
          memo
        end
      end

      def constraints_diff (environment_diff)
        Hash[Hash[environment_diff.map{|k,v| [k, v.split(" changed to ").map{|x|x.gsub("= ","")}]}].map{|k,v|[k,calc_diff(k,v)]}]
      end

      def calc_diff(cookbook, version)
        components =  version.map{|v|v.split(".")}

        if components.length < 2
          ui.warn "#{cookbook} has no remote version to diff against!"
          return 0
        end

        if components[1][0].to_i != components[0][0].to_i
          return (components[1][0].to_i - components[0][0].to_i)*100
        elsif components[1][1].to_i != components[0][1].to_i
          return (components[1][1].to_i - components[0][1].to_i)*10
        else
          return (components[1][2].to_i - components[0][2].to_i)
        end
      end

      def ensure_cookbook_path!
        if config[:cookbook_path].nil?
          ui.fatal "No default cookbook_path; Specify with -o or fix your knife.rb."
          show_usage
          exit(1)
        end
      end

      def unload_berkshelf_if_specified
        # Temporary fix for #138 to allow Berkshelf functionality
        # to be bypassed until #85 has been completed and Berkshelf 3 support added
        if spork_config.skip_berkshelf
          ui.warn "Unloading Berkshelf as skip_berkshelf option found in config"
          Object.send(:remove_const, :Berkshelf) if defined?(::Berkshelf)
        end
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end
  end
end
