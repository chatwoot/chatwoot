# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Elasticsearch::Prepend
    include NewRelic::Agent::Instrumentation::Elasticsearch

    def perform_request(*args)
      perform_request_with_tracing(*args) { super }
    end
  end
end
