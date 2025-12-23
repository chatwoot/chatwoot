# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module LatestChanges
    def self.default_changelog
      File.join(File.dirname(__FILE__), '..', '..', 'CHANGELOG.md')
    end

    FOOTER = <<EOS
    See https://github.com/newrelic/newrelic-ruby-agent/blob/main/CHANGELOG.md for a full list of
    changes.
EOS

    def self.read(changelog = default_changelog)
      changes = extract_latest_changes(File.read(changelog))
      changes << FOOTER

      changes.join("\n")
    end

    # Patches are expected to have the format of our normal item, with the
    # precise version number included in the line in parens. For example:
    #
    # * This is a patch item (3.7.1.188)
    def self.read_patch(patch_level, changelog = default_changelog)
      latest = extract_latest_changes(File.read(changelog))
      changes = ["## v#{patch_level}", '']

      current_item = nil
      latest.each do |line|
        if /^\s*\*.*/.match?(line)
          if /\(#{patch_level}\)/.match?(line)
            # Found a patch level item, so start tracking the lines!
            current_item = line
          else
            # Found an item that isn't our patch level, so don't grab it
            current_item = nil
          end
        end

        if current_item
          changes << line
        end
      end

      changes.join("\n")
    end

    def self.extract_latest_changes(contents)
      changes = []
      version_count = 0
      contents.each_line do |line|
        if /##\s+v[\d.]+/.match?(line)
          version_count += 1
        end
        break if version_count >= 2

        changes << line.sub(/^  \* /, '* ').chomp
      end
      changes
    end
  end
end
