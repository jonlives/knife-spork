require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class GitAll < Plugin
      name :gitall

      def perform; end

      # Data Bag Git wrappers
      # These won't work until: https://github.com/jonlives/knife-spork/issues/156
      def before_databagcreate
        git_pull(data_bag_path)
      end
      def after_databagcreate
      end

      # Node Git wrappers
      def before_nodecreate
        git_pull(node_path)
        if File.exist?(File.join(node_path, object_name + '.json'))
          ui.error 'Node already exists in local git, aborting creation'
          exit 1
        end
      end
      def before_nodedelete
        git_pull(node_path)
      end
      def before_nodeedit
        git_pull(node_path)
        if !File.exist?(File.join(node_path, object_name + '.json'))
          ui.error 'Node does not exist in git, please bootstrap one first'
          exit 1
        end
      end
      def after_nodeedit
        save_node(object_name) unless object_difference == ''
      end
      def after_nodedelete
        delete_node(object_name)
      end
      def after_nodecreate
        save_node(object_name) unless object_difference == ''
      end

      # Role Git wrappers
      def before_rolecreate
        git_pull(role_path)
        if File.exist?(File.join(role_path, object_name + '.json'))
          ui.error 'Role already exists in local git, aborting creation'
          exit 1
        end
      end
      def before_roledelete
        git_pull(role_path)
      end
      def before_roleedit
        git_pull(role_path)
        if !File.exist?(File.join(role_path, object_name + '.json'))
          ui.error 'Role does not exist in git, please create it first with spork'
          exit 1
        end
      end
      def after_roleedit
        save_role(object_name) unless object_difference == ''
      end
      def after_roledelete
        delete_role(object_name)
      end
      def after_rolecreate
        save_role(object_name) unless object_difference == ''
      end

      # Environmental Git wrappers
      def before_environmentcreate
        git_pull(environment_path)
        if File.exist?(File.join(environment_path, object_name + '.json'))
          ui.error 'Environment already exists in local git, aborting creation'
          exit 1
        end
      end
      def before_environmentdelete
        git_pull(environment_path)
      end
      def before_environmentedit
        git_pull(environment_path)
        if !File.exist?(File.join(environment_path, object_name + '.json'))
          ui.error 'Environment does not exist in git, please create it first with spork'
          exit 1
        end
      end
      def after_environmentedit
        save_environment(object_name) unless object_difference == ''
      end
      def after_environmentdelete
        delete_environment(object_name)
      end
      def after_environmentcreate
        save_environment(object_name) unless object_difference == ''
      end

      # Generic tasks used by wrappers
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
        git_push(branch) if config.auto_push
      end
      def delete_role(role)
        git_rm(role_path, "#{role}.json")
        git_commit(role_path, "[ROLE] Deleted #{role}")
        git_push(branch) if config.auto_push
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

      # Private stuff
      private
      def data_bag_path
        config.data_bag_path.nil? ? 'data_bags' : config[:data_bag_path]
      end
      def role_path
        config.role_path.nil? ? 'roles' : config[:role_path]
      end
      def node_path
        config.node_path.nil? ? 'nodes' : config[:node_path]
      end
      def remote
        config.remote || 'origin'
      end
      def branch
        config.branch || 'master'
      end
      def git
        safe_require 'git'
        log = Logger.new(STDOUT)
        log.level = Logger::WARN
        @git ||= begin
          cwd = FileUtils.pwd()
          ::Git.open(get_parent_dir(cwd) , :log => log)
        rescue Exception => _e
          ui.error "You are not currently in a git repository #{cwd}. Please ensure you are in a git repo, a repo subdirectory, or remove the git plugin from your KnifeSpork configuration!"
          puts _e
          exit(0)
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
      def is_repo?(path)
        _output = IO.popen("cd #{path} && git rev-parse --git-dir 2>&1")
        Process.wait
        if $? != 0
          ui.warn "#{path} is not a git repo, skipping..."
          return false
        else
          return true
        end
      end
      def git_pull(path)
        if is_repo?(path)
          ui.msg "Git: Pulling latest changes from #{path}"
          output = IO.popen("git pull 2>&1")
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
          git.push remote, branch
        rescue ::Git::GitExecuteError => e
          ui.error "Could not push to #{branch}: #{e.message}"
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
    end
  end
end
