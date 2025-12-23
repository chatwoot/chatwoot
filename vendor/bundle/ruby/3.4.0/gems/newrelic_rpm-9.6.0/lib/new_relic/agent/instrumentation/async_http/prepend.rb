# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module AsyncHttp::Prepend
    include NewRelic::Agent::Instrumentation::AsyncHttp

    def call(method, url, headers = nil, body = nil)
      call_with_new_relic(method, url, headers, body) { |hdr| super(method, url, hdr, body) }
    end
  end
end
