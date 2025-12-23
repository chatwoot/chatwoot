# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'helpers/newrelicyml'

namespace :newrelic do
  desc 'Update newrelic.yml with latest config options from default_source.rb'
  task :update_newrelicyml do
    NewRelicYML.write_file
    puts 'newrelic.yml updated'
  end
end
