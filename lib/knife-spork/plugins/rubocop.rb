require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Rubocop < Plugin
      name :rubocop
      hooks :after_check, :before_upload

      def perform
        if config.use_cookstyle
          safe_require 'cookstyle'
        else
          safe_require 'rubocop'
        end
        safe_require 'rubocop/cli'
        safe_require 'rubocop/config_store'

        if Gem::Specification.find_all_by_name("rubocop").empty?
          ui.fatal "The knife-spork rubocop plugin requires rubocop."
          exit 1
        end

        base_options = []
	base_options = base_options.concat([ "-D" ]) if config.show_name  # Lists the name of the offense along with the description
	base_options = base_options.concat([ "--auto-correct" ]) if config.autocorrect
	base_options = base_options.concat([ "--out", config.out_file ]) if config.out_file # Specify a file output rather than STDOUT for the specific errors
	base_options = base_options.concat([ "--fail-level", config.sev_level ]) if config.sev_level # Specify a severity level for when rubocop should fail
	base_options = base_options.concat([ "--lint"]) if config.lint  # Only run lint checks

        cookbooks.each do |cookbook|
          ui.info "Running rubocop against #{cookbook.name}@#{cookbook.version}..."

          cookbook_path = cookbook.root_dir

          ui.info cookbook_path

          options = [ cookbook_path ]

          cli = defined?(RuboCop) ? ::RuboCop::CLI.new : ::Rubocop::CLI.new
          result = cli.run(options)

          unless result  == 0
            ui.error "Rubocop failed!"
            exit(1) if config.epic_fail
          else
            ui.info "Passed!"
          end
        end
      end

      def epic_fail?
        config.epic_fail.nil? ? 'true' : config.epic_fail
      end
    end
  end
end
