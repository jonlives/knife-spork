require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Changelog < Plugin
      name :changelog

      def perform; end

      def after_bump
        cookbooks.each do |cookbook|
          changelog_file = "#{cookbook_path_for(cookbook)}/CHANGELOG.md"
          metadata_file = "#{cookbook_path_for(cookbook)}/metadata.rb"

          # Read the current CHANGELOG.md contents into an Array
          f = File.open(changelog_file, 'r+')
          lines = f.readlines
          f.close

          # Pull the new version from the metadata.rb file on disk (this is not yet updated in the CookbookVersion object)
          version_line = File.open(metadata_file, 'r').readlines.select { |line| line.start_with?('version') }
          version_line = version_line[0]
          version = version_line.match(/[0-9\.]+/)[0]

          # Compose the CHANGELOG entry, preserving header lines if configured
          new_lines = []
          if preserve_lines > 0
            new_lines = lines[0..(preserve_lines-1)] 
          end
          new_lines = new_lines + changelog_entry_for(version)
          new_lines = new_lines + lines[preserve_lines..-1]

          # Write the new CHANGELOG.md file
          output = File.new(changelog_file, 'w')
          output.puts new_lines
          output.close
          ui.info "CHANGELOG.md for cookbook #{cookbook.name} successfully updated"
        end
      end

      def preserve_lines
        config.preserve_lines || 0
      end

      def default_comment
        config.default_comment || "Bump"
      end

      def changelog_entry_for version
        entry = [version]
        entry << '-' * version.length
        entry << "- [#{current_user}] #{default_comment}"
        entry << ''
        entry
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
