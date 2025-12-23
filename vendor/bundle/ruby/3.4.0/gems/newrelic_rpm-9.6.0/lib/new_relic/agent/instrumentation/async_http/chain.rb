# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module AsyncHttp::Chain
    def self.instrument!
      ::Async::HTTP::Internet.class_eval do
        include NewRelic::Agent::Instrumentation::AsyncHttp

        alias_method(:call_without_new_relic, :call)

        def call(method, url, headers = nil, body = nil)
          call_with_new_relic(method, url, headers, body) do |hdr|
            call_without_new_relic(method, url, hdr, body)
          end
        end
      end
    end
  end
end
