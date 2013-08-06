require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Git < Plugin
      name :git

      def perform; end

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
      end

      private
      def git
        safe_require 'git'
        log = Logger.new(STDOUT)
        log.level = Logger::WARN
        @git ||= begin
          ::Git.open('.', :log => log)
        rescue
          ui.error 'You are not currently in a git repository. Please ensure you are in a git repo, a repo subdirectory, or remove the git plugin from your KnifeSpork configuration!'
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
          output = IO.popen("git pull 2>&1")
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

      # Commit changes, if any
      def git_commit
        begin
          git.add('.')
          `git ls-files --deleted`.chomp.split("\n").each{ |f| git.remove(f) }
          git.commit_all "[KnifeSpork] Bumping cookbooks:\n#{cookbooks.collect{|c| "  #{c.name}@#{c.version}"}.join("\n")}"
        rescue ::Git::GitExecuteError; end
      end

      def git_push(tags = false)
        begin
          git.push remote, branch, tags
        rescue ::Git::GitExecuteError => e
          ui.error "Could not push to remote #{remote}/#{branch}. Does it exist?"
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
          cookbook.root_path
        end
      end
    end
  end
end
