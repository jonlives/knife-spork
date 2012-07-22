require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Git < Plugin
      name :git

      def perform; end

      def before_bump
        git_pull
      end

      def after_bump
        git_pull
        git_commit
        git_push
      end

      def after_promote
        git_commit
        git_tag("knifespork-#{tag_name}")
        git_push(true)
      end

      private
      def git
        safe_require 'git'

        @git ||= begin
          ::Git.open('.')
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
        git.branch.stashes.save('[KnifeSpork] Stashing local changes')

        begin
          git.pull remote, branch
        rescue ::Git::GitExecuteError => e
          ui.error "Could not pull from remote #{remote}/#{branch}. Does it exist?"
        end

        git.branch.stashes.apply
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
