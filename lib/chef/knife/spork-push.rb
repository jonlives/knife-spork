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

      changelog_add_version(changelog_file)
      if config[:changelog_message] 
        write_changelog(config[:changelog_message], changelog_file)
      else
        edit_changelog(changelog_file)
      end
      run_plugins(:before_push)
      push
      run_plugins(:after_push)
    end

    private
    def push; end

    def changelog_add_version(file)
      message = "## #{@cookbook.version}:\n\n"
      write_changelog(message, file)
    end

    def edit_changelog(file)
      system("#{config[:editor]} #{file}")
    end

    def write_changelog(message, file)
      File.open(file, 'a') { |file| file.write(message) }
    end

  end
end
