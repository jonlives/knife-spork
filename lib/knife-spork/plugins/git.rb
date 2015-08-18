require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Git < Plugin
      name :git

      def perform; end

      # Role Git wrappers
      def before_rolecreate
        if config.auto_push
          if !File.directory?(role_path)
            ui.error "Role path #{role_path} does not exist"
            exit 1
          end
          git_pull(role_path)
          if File.exist?(File.join(role_path, object_name + '.json'))
            ui.error 'Role already exists in local git, aborting creation'
            exit 1
          end
        end
      end
      def after_rolecreate
        if config.auto_push
          if !File.directory?(role_path)
            ui.error "Role path #{role_path} does not exist"
            exit 1
          end
          save_role(object_name) unless object_difference == ''
        end
      end
      def before_roleedit
        if config.auto_push
          git_pull(role_path)
          if !File.exist?(File.join(role_path, object_name + '.json'))
            ui.error 'Role does not exist in git, please create it first with spork'
            exit 1
          end
        end
      end
      def after_roleedit
        if config.auto_push
          save_role(object_name) unless object_difference == ''
        end
      end
      def before_roledelete
        if config.auto_push
          git_pull(role_path)
        end
      end
      def after_roledelete
        if config.auto_push
          delete_role(object_name)
        end
      end

      # Environmental Git wrappers
      def before_environmentcreate
        if config.auto_push
          if !File.directory?(environment_path)
            ui.error "Environment path #{environment_path} does not exist"
            exit 1
          end
          git_pull(environment_path)
          if File.exist?(File.join(environment_path, object_name + '.json'))
            ui.error 'Environment already exists in local git, aborting creation'
            exit 1
          end
        end
      end
      def after_environmentcreate
        if config.auto_push
          save_environment(object_name) unless object_difference == ''
        end
      end
      def before_environmentedit
        if config.auto_push
          git_pull(environment_path)
          if !File.exist?(File.join(environment_path, object_name + '.json'))
            ui.error 'Environment does not exist in git, please create it first with spork'
            exit 1
          end
        end
      end
      def after_environmentedit
        if config.auto_push
          save_environment(object_name) unless object_difference == ''
        end
      end
      def before_environmentdelete
        if config.auto_push
          git_pull(environment_path)
        end
      end
      def after_environmentdelete
        if config.auto_push
          delete_environment(object_name)
        end
      end

      # Node Git wrappers
      def before_nodecreate
        if config.auto_push
          git_pull(node_path)
          if File.exist?(File.join(node_path, object_name + '.json'))
            ui.error 'Node already exists in local git, aborting creation'
            exit 1
          end
        end
      end
      def after_nodecreate
        if config.auto_push
          save_node(object_name) unless object_difference == ''
        end
      end
      def before_nodeedit
        if config.auto_push
          git_pull(node_path)
          if !File.exist?(File.join(node_path, object_name + '.json'))
            ui.error 'Node does not exist in git, please bootstrap one first'
            exit 1
          end
        end
      end
      def after_nodeedit
        if config.auto_push
          save_node(object_name) unless object_difference == ''
        end
      end
      def before_nodedelete
        if config.auto_push
          git_pull(node_path)
        end
      end
      def after_nodedelete
        if config.auto_push
          delete_node(object_name)
        end
      end
 
      def before_bump
        git_pull(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
        git_pull_submodules(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
        cookbooks.each do |cookbook|
          git_pull(cookbook_path_for(cookbook))
          git_pull_submodules(cookbook_path_for(cookbook))
        end
      end

      def before_upload
        git_pull(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
        git_pull_submodules(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
        cookbooks.each do |cookbook|
          git_pull(cookbook_path_for(cookbook))
          git_pull_submodules(cookbook_path_for(cookbook))
        end
      end

      def before_promote
        cookbooks.each do |cookbook|
          git_pull(environment_path) unless cookbook_path_for(cookbook).include?(environment_path.gsub"/environments","")
          git_pull_submodules(environment_path) unless cookbook_path_for(cookbook).include?(environment_path.gsub"/environments","")
          git_pull(cookbook_path_for(cookbook))
          git_pull_submodules(cookbook_path_for(cookbook))
        end
      end

      def after_bump
        cookbooks.each do |cookbook|
          git_add(cookbook_path_for(cookbook),"metadata.rb")
        end
      end

      def after_promote_local
        environments.each do |environment|
          git_add(environment_path,"#{environment}.json")
        end
        if config.auto_push
          branch =  if not config.branch.nil?
                      config[:branch] 
                    else 
                      "master"
                    end

          git_commit(environment_path, "promote #{cookbooks.collect{ |c| "#{c.name}@#{c.version}" }.join(",")} to #{environments.join(",")}")
          git_push(branch)
        end
      end
    
      def save_node(node)
        json = JSON.pretty_generate(Chef::Node.load(node))
        node_file = File.expand_path( File.join(node_path, "#{node}.json") )
        File.open(node_file, 'w'){ |f| f.puts(json) }
        git_add(node_path, "#{node}.json")
        git_commit(node_path, "[NODE] Updated #{node}")
        git_push(branch) if config.auto_push
      end
      def delete_node(node)
        git_rm(node_path, "#{node}.json")
        git_commit(node_path, "[NODE] Deleted #{node}")
        git_push(branch) if config.auto_push
      end

      def save_role(role)
        json = JSON.pretty_generate(Chef::Role.load(role))
        role_file = File.expand_path( File.join(role_path, "#{role}.json") )
        File.open(role_file, 'w'){ |f| f.puts(json) }
        git_add(role_path, "#{role}.json")
        git_commit(role_path, "[ROLE] Updated #{role}")
        git_push(branch)
      end
      def delete_role(role)
        git_rm(role_path, "#{role}.json")
        if config.auto_push
          git_commit(role_path, "[ROLE] Deleted #{role}")
          git_push(branch)
        end
      end

      def save_environment(environment)
        json = JSON.pretty_generate(Chef::Environment.load(environment))
        environment_file = File.expand_path( File.join(environment_path, "#{environment}.json") )
        File.open(environment_file, 'w'){ |f| f.puts(json) }
        git_add(environment_path, "#{environment}.json")
        git_commit(environment_path, "[ENV] Updated #{environment}")
        git_push(branch) if config.auto_push
      end
      def delete_environment(environment)
        git_rm(environment_path, "#{environment}.json")
        git_commit(environment_path, "[ENV] Deleted #{environment}")
        git_push(branch) if config.auto_push
      end

      private
      def git
        safe_require 'git'
        log = Logger.new(STDOUT)
        log.level = Logger::WARN
        @git ||= begin
          cwd = FileUtils.pwd()
          ::Git.open(get_parent_dir(cwd) , :log => log)
        rescue Exception => e  
          ui.error "You are not currently in a git repository #{cwd}. Please ensure you are in a git repo, a repo subdirectory, or remove the git plugin from your KnifeSpork configuration!"
          exit(0)
        end
      end

      # In this case, a git pull will:
      #   - Stash local changes
      #   - Pull from the remote
      #   - Pop the stash
      def git_pull(path)
        if is_repo?(path)
          ui.msg "Git: Pulling latest changes from #{path}"
          output = IO.popen("cd #{path} && git pull 2>&1")
          Process.wait
          exit_code = $?
          if !exit_code.exitstatus ==  0
            ui.error "#{output.read()}\n"
            exit 1
          end
        end
      end

      def git_pull_submodules(path)
        if is_repo?(path)
          ui.msg "Pulling latest changes from git submodules (if any)"
          top_level = `cd #{path} && git rev-parse --show-toplevel 2>&1`.chomp
          if is_submodule?(top_level)
            top_level = get_parent_dir(top_level)
          end
          output = IO.popen("cd #{top_level} && git submodule foreach git pull 2>&1")
          Process.wait
          exit_code = $?
          if !exit_code.exitstatus ==  0
              ui.error "#{output.read()}\n"
              exit 1
          end
        end
      end

      def git_add(filepath,filename)
        if is_repo?(filepath)
          ui.msg "Git add'ing #{filepath}/#{filename}"
          output = IO.popen("cd #{filepath} && git add #{filename}")
          Process.wait
          exit_code = $?
          if !exit_code.exitstatus ==  0
              ui.error "#{output.read()}\n"
              exit 1
          end
        end
      end
      
      def git_commit(filepath, msg)
        begin
          if is_repo?(filepath)
            ui.msg "Git: Committing changes..."
            git.commit msg
          end
        rescue ::Git::GitExecuteError; 
        end
      end

      def git_push(branch)
        begin
            ui.msg "Git: Pushing to #{branch}"
            git.push "origin", branch
        rescue ::Git::GitExecuteError => e
          ui.error "Could not push to master: #{e.message}"
        end
      end

      def git_rm(filepath, filename)
        if is_repo?(filepath)
          ui.msg "Git rm'ing #{filepath}/#{filename}"
          output = IO.popen("cd #{filepath} && git rm #{filename}")
          Process.wait
          exit_code = $?
          if !exit_code.exitstatus ==  0
            ui.error "#{output.read()}\n"
            exit 1
          end
        end
      end

      def git_tag(tag)
        begin
          git.add_tag(tag)
        rescue ::Git::GitExecuteError => e
          ui.error "Could not tag #{tag_name}. Does it already exist?"
          ui.error 'You may need to delete the tag before running promote again.'
        end
      end

      def is_repo?(path)
        output = IO.popen("cd #{path} && git rev-parse --git-dir 2>&1")
        Process.wait
        if $? != 0
            ui.warn "#{path} is not a git repo, skipping..."
            return false
        else
            return true
        end
      end

      def is_submodule?(path)
        top_level = `cd #{path} && git rev-parse --show-toplevel 2>&1`.chomp
        output = IO.popen("cd #{top_level}/.. && git rev-parse --show-toplevel 2>&1")
        Process.wait
        if $? != 0
          return false
        else
          return true
        end
      end

      def get_parent_dir(path)
        top_level = path
        return_code = 0
        while return_code == 0
          output = IO.popen("cd #{top_level}/.. && git rev-parse --show-toplevel 2>&1")
          Process.wait
          return_code = $?
          cmd_output = output.read.chomp
          #cygwin, I hate you for making me do this
          if cmd_output.include?("fatal: Not a git repository")
            return_code = 1
          end
          if return_code == 0
            top_level = cmd_output
          end
        end
        top_level
      end

      def remote
        config.remote || 'origin'
      end

      def branch
        config.branch || 'master'
      end

      def tag_name
        cookbooks.collect{|c| "#{c.name}@#{c.version}"}.join('-')
      end

      def cookbook_path_for cookbook
        if defined?(Berkshelf) and cookbook.is_a? Berkshelf::CachedCookbook
          cookbook.path.to_s
        else
          cookbook.root_dir
        end
      end
    end
  end
end
