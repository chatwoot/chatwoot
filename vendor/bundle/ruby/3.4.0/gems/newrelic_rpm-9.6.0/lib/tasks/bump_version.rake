# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'helpers/version_bump'

namespace :newrelic do
  namespace :version do
    desc 'Returns the current version'
    task :current do
      puts "#{NewRelic::VERSION::STRING}"
    end

    desc 'Update version file and changelog to next version'
    task :bump, [:format] => [] do |t, args|
      new_version = VersionBump.update_version
      VersionBump.update_changelog(new_version)
      puts "New version: #{new_version}"
    end
  end
end
