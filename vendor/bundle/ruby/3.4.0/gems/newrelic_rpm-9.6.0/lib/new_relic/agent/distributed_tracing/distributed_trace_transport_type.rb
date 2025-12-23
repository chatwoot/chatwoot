# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module DistributedTraceTransportType
      extend self

      ALLOWABLE_TRANSPORT_TYPES = [
        NewRelic::UNKNOWN,
        NewRelic::HTTP,
        NewRelic::HTTPS,
        'Kafka',
        'JMS',
        'IronMQ',
        'AMQP',
        'Queue',
        'Other'
      ].freeze

      URL_SCHEMES = {
        'http' => NewRelic::HTTP,
        'https' => NewRelic::HTTPS
      }.freeze

      RACK_URL_SCHEME = 'rack.url_scheme'

      def from(value)
        ALLOWABLE_TRANSPORT_TYPES.include?(value) ? value : NewRelic::UNKNOWN
      end

      def for_rack_request(request)
        URL_SCHEMES[request[RACK_URL_SCHEME]]
      end
    end
  end
end
