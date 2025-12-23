# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  PRIORITY_PRECISION = 6

  EMPTY_ARRAY = [].freeze
  EMPTY_HASH = {}.freeze
  EMPTY_STR = ''

  HTTP = 'HTTP'
  HTTPS = 'HTTPS'
  UNKNOWN = 'Unknown'

  FORMAT_NON_RACK = 0
  FORMAT_RACK = 1

  NEWRELIC_KEY = 'newrelic'
  CANDIDATE_NEWRELIC_KEYS = [
    NEWRELIC_KEY,
    'NEWRELIC',
    'NewRelic',
    'Newrelic'
  ].freeze

  TRACEPARENT_KEY = 'traceparent'
  TRACESTATE_KEY = 'tracestate'

  STANDARD_OUT = 'STDOUT'

  HTTP_TRACEPARENT_KEY = "HTTP_#{TRACEPARENT_KEY.upcase}"
  HTTP_TRACESTATE_KEY = "HTTP_#{TRACESTATE_KEY.upcase}"
  HTTP_NEWRELIC_KEY = "HTTP_#{NEWRELIC_KEY.upcase}"

  CONNECT_RETRY_PERIODS = [15, 15, 30, 60, 120, 300]
  MAX_RETRY_PERIOD = 300

  SLASH = '/'
  ROOT = SLASH
end
