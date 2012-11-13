require 'chef/knife'
require 'knife-spork/runner'

module KnifeSpork
  class SporkPush < Chef::Knife
    include KnifeSpork::Runner

    TYPE_INDEX = { :major => 0, :minor => 1, :patch => 2, :manual => 3 }.freeze

    banner 'knife spork push COOKBOOK - push changes to github and submit a pull request'

    option :changelog_message,
      :short => '-m MESSAGE',
      :long => '--changelog-message MESSAGE',
      :description => 'Message to add to the changelog for this cookbook version',
      :default => false

    def run
      self.config = Chef::Config.merge!(config)

      if @name_args.empty?
        show_usage
        ui.error("You must specify at least a cookbook name")
        exit 1
      end

      @cookbook = load_cookbook(name_args.first)
      changelog_file = File.join(@cookbook.root_dir, "CHANGELOG.md")

      if config[:changelog_message] 
        message = changelog_add_version + "* #{config[:changelog_message]}\n\n"
        write_changelog(message, changelog_file)
      else
        message = changelog_add_version + "* ADD YOUR CHANGE MESSAGE HERE\n\n"
        write_changelog(message, changelog_file)
        edit_changelog(changelog_file)
      end
      run_plugins(:before_push)
      push
      run_plugins(:after_push)
    end

    private
    def push; end

    def changelog_add_version
      "## #{@cookbook.version}:\n\n"
    end

    def edit_changelog(file)
      unless system("#{config[:editor]} #{file}")
        ui.error("Please set EDITOR environment variable")
        exit(1)
      end
    end

    def write_changelog(message, file)
      old_changelog = File.read(file)
      new_changelog = message + old_changelog
      File.open(file, 'w') { |file| file.write(new_changelog) }
    end

  end
end
