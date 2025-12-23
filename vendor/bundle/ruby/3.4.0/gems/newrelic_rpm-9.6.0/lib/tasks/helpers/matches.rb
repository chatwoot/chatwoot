# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module Matches
  def look_for_seed(tasks)
    matches = tasks.map { |t| /(seed=.*?)[,\]]/.match(t) }.compact
    if matches.any?
      matches.first[1]
    end
  end
end
