# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

namespace :newrelic do
  desc 'Install a default config/newrelic.yml file'
  task :install do
    load File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'install.rb'))
  end

  desc 'Gratefulness is always appreciated'
  task :thanks do
    puts 'The Ruby agent team is grateful to Jim Weirich for his kindness and his code. He will be missed.'
  end
end
