# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This is required to load in task definitions
Dir.glob(File.join(File.dirname(__FILE__), '*.rake')) do |file|
  load file
end
