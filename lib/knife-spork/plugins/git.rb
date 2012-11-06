require 'knife-spork/plugins/plugin'
require 'net/http'
require 'net/https'
require 'json'

module KnifeSpork
  module Plugins
    class Git < Plugin
      name :git

      def perform
        if config.feature_branching
          if cookbooks.length > 1
            ui.error "Git branching strategy only supports working on one cookbook at a time."
          end
        end
      end

      def before_push
        git_commit
      end
        
      def before_bump
        if config.feature_branching
          git_branch(branch)
        else
          git_pull(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
          git_pull_submodules(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
          cookbooks.each do |cookbook|
            git_pull(cookbook.root_dir)
            git_pull_submodules(cookbook.root_dir)
          end
        end
      end

      def before_create
        before_bump
      end

      def before_upload
        unless config.feature_branching
          git_pull(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
          git_pull_submodules(environment_path) unless cookbook_path.include?(environment_path.gsub"/environments","")
          cookbooks.each do |cookbook|
            git_pull(cookbook.root_dir)
            git_pull_submodules(cookbook.root_dir)
          end
        end
      end

      def before_promote
        unless config.feature_branching
          cookbooks.each do |cookbook|
            git_pull(environment_path) unless cookbook.root_dir.include?(environment_path.gsub"/environments","")
            git_pull_submodules(environment_path) unless cookbook.root_dir.include?(environment_path.gsub"/environments","")
            git_pull(cookbook.root_dir)
            git_pull_submodules(cookbook.root_dir)
          end
        end
      end

      def after_push
        git_push
        github_submit_pull_request
      end

      def after_bump
        cookbooks.each do |cookbook|
          git_add(cookbook.root_dir,"metadata.rb")
        end
      end

      def after_create
        after_bump
      end

      def after_promote_local
        unless config.feature_branching
          environments.each do |environment|
            git_add(environment_path,"#{environment}.json")
          end
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

      def github_api
        http = Net::HTTP.new('api.github.com', 443)
        http.use_ssl = true
        http
      end

      def github_submit_pull_request
        request = Net::HTTP::Post.new("/repos/#{config.github.repo}/pulls", initheader = { 'Content-Type' => 'application/json' })
        request.basic_auth config.github.user, config.github.pass
        request.body = github_pull_request_data
        response = github_api.start { |http| http.request(request) }
        if response.code == "201" && response.message == "Created"
          response_json = JSON.parse(response.body)
          ui.msg("Created Pull Request #{response_json['number']} on #{config.github.repo}: #{response_json['html_url']}")
        else
          ui.error("Something went wrong during the pull request:\nResponse Code:#{response.code}\nMessage:#{response.message}\n#{response.body}")
          exit(1)
        end
      end

      def github_pull_request_data
        repo_user = config.github.repo.split('/')[0]
        data = {
          "title" => "KNIFE-SPORK-METADATA=PUSH_TYPE:COOKBOOK NAME:#{cookbooks.first.name} VERSION:#{cookbooks.first.version}",
          "body" => "#{current_user} bumped #{cookbooks.first.name}@#{cookbooks.first.version} via KnifeSpork",
          "head" => "#{repo_user}:#{branch}",
          "base" => "master"
        }.to_json
        data
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
          output = IO.popen("git submodule foreach git pull 2>&1")
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
          git.commit_all "[KnifeSpork] Bumping cookbooks:#{cookbooks.collect{|c| "  #{c.name}@#{c.version}"}.join("\n")}"
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

      def git_branch(branch)
        begin
          git.branch(branch).checkout
          ui.msg("On branch #{branch}")
        rescue ::Git::GitExecuteError => e
          ui.error("Could not checkout branch #{branch}: #{e.message}")
          exit(1)
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
      
      def remote
        config.remote || 'origin'
      end

      def branch
        if config.feature_branching
          "#{config.initials}-cookbooks-#{cookbooks.first.name}"
        else
          config.branch || 'master'
        end
      end

      def tag_name
        cookbooks.collect{|c| "#{c.name}@#{c.version}"}.join('-')
      end

    end
  end
end
