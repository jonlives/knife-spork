require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Git < Plugin
      name :git

      def perform; end

      def before_bump
        git_pull
        git_pull_submodules
      end

      def before_upload
        git_pull
        git_pull_submodules
      end

      def before_promote
        git_pull
        git_pull_submodules
      end

      def after_bump
        cookbooks.each do |cookbook|
          git_add("#{cookbook.root_dir}/metadata.rb")
        end
      end

      def after_promote_local
        environments.each do |environment|
          git_add("./environments/#{environment}.json")
        end
      end

      private
      def git
        safe_require 'git'

        @strio ||= StringIO.new
        @git ||= begin
          ::Git.open('.', :log => Logger.new(STDOUT))
        rescue
          ui.error 'You are not currently in a git repository. Ensure you are in the proper working directory or remove the git plugin from your KnifeSpork configuration!'
          exit(0)
        end
      end

      # In this case, a git pull will:
      #   - Stash local changes
      #   - Pull from the remote
      #   - Pop the stash
      def git_pull
        ui.msg "Pulling latest changes from remote Git repo."
        output = IO.popen ("git pull 2>&1")
        Process.wait
        exit_code = $?
        if !exit_code.exitstatus ==  0
            ui.error "#{output.read()}\n"
            exit 1
        end
      end

      def git_pull_submodules
        ui.msg "Pulling latest changes from git submodules (if any)"
        output = IO.popen ("git submodule foreach git pull 2>&1")
        Process.wait
        exit_code = $?
        if !exit_code.exitstatus ==  0
            ui.error "#{output.read()}\n"
            exit 1
        else
             ui.msg "#{output.read()}\n"
        end
      end
      
      def git_add(filepath)
       begin
          ui.msg "Git add'ing #{filepath}"
          git.add("#{filepath}")
        rescue ::Git::GitExecuteError => e
          ui.error "Git: Something went wrong with git add #{filepath}. Please try running git add manually."
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

      def remote
        config.remote || 'origin'
      end

      def branch
        config.branch || 'master'
      end

      def tag_name
        cookbooks.collect{|c| "#{c.name}@#{c.version}"}.join('-')
      end
    end
  end
end
