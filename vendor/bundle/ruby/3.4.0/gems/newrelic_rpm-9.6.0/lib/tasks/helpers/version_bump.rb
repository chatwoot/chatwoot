# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module VersionBump
  MAJOR = 0
  MINOR = 1
  TINY = 2
  VERSION = {major: MAJOR, minor: MINOR, tiny: TINY}

  # Updates version.rb with new version number
  def self.update_version
    bump_type = determine_bump_type
    file = read_file('lib/new_relic/version.rb')
    new_version = {}

    VERSION.each do |key, current|
      file.gsub!(/(#{key.to_s.upcase} = )(\d+)/) do
        match = Regexp.last_match

        new_version[key] = if bump_type == current # bump type, increase by 1
          match[2].to_i + 1
        elsif bump_type < current # right of bump type, goes to 0
          0
        else # left of bump type, stays the same
          match[2].to_i
        end

        match[1] + new_version[key].to_s
      end
    end

    write_file('lib/new_relic/version.rb', file)
    new_version.values.join('.')
  end

  def self.read_file(path)
    File.read(File.expand_path(path))
  end

  def self.write_file(path, file)
    File.write(File.expand_path(path), file)
  end

  # Determined version based on if changelog has a feature or not for version
  def self.determine_bump_type
    file = read_file('CHANGELOG.md')
    lines = file.split('## ')[1].split('- **')
    return MAJOR if lines.first.include?('Major version')
    return MINOR if lines.any? { |line| line.include?('Feature:') }

    TINY
  end

  # Replace dev with version number in changelog
  def self.update_changelog(version)
    file = read_file('CHANGELOG.md')
    file.gsub!('## dev', "## v#{version}")
    file.gsub!('Version <dev>', "Version #{version}")
    write_file('CHANGELOG.md', file)
  end
end
