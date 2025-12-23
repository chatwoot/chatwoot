# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Elasticsearch::Chain
    def self.instrument!
      to_instrument = if ::Gem::Version.create(::Elasticsearch::VERSION) <
          ::Gem::Version.create('8.0.0')
        ::Elasticsearch::Transport::Client
      else
        ::Elastic::Transport::Client
      end

      to_instrument.class_eval do
        include NewRelic::Agent::Instrumentation::Elasticsearch

        alias_method(:perform_request_without_tracing, :perform_request)
        alias_method(:perform_request, :perform_request_with_tracing)

        def perform_request(*args)
          perform_request_with_tracing(*args) do
            perform_request_without_tracing(*args)
          end
        end
      end
    end
  end
end
