# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# @api public
module NewRelic
  # This module contains Rack middlewares used by the Ruby agent.
  #
  # Generally, these middlewares should be injected automatically when starting
  # your application. If automatic injection into the middleware chain is not
  # working for some reason, you may also include them manually.
  #
  #
  # @api public
  module Rack
  end
end
