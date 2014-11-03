require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Foodcritic < Plugin
      name :foodcritic
      hooks :after_check, :before_upload

      def perform
        safe_require 'foodcritic'

        if Gem::Specification.find_all_by_name("foodcritic", ">= 3.0.0").empty?
          ui.fatal "The knife-spork foodcritic plugin requires foodcritic >= 3.0.0. Please install a more recent foodcritic version."
          exit 1
        end

        tags = config.tags || []
        fail_tags = config.fail_tags || ['any']
        include_rules = config.include_rules || []

        cookbooks.each do |cookbook|
          ui.info "Running foodcritic against #{cookbook.name}@#{cookbook.version}..."

          cookbook_path = cookbook.root_dir

          ui.info cookbook_path

          options = {:tags => tags, :fail_tags => fail_tags, :include_rules => include_rules, :cookbook_paths => [cookbook_path]}
          review = ::FoodCritic::Linter.new.check(options)

          if review.failed?
            ui.error "Foodcritic failed!"
            review.to_s.split("\n").each{ |r| ui.error r.to_s }
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
