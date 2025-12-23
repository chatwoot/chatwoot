# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'monitors/inbound_request_monitor'

require_relative 'monitors/synthetics_monitor'

require_relative 'monitors/cross_app_monitor'
require_relative 'monitors/distributed_tracing_monitor'

module NewRelic
  module Agent
    class Monitors
      attr_reader :cross_app_monitor
      attr_reader :synthetics_monitor
      attr_reader :distributed_tracing_monitor

      def initialize(events)
        @synthetics_monitor = NewRelic::Agent::SyntheticsMonitor.new(events)
        @cross_app_monitor = NewRelic::Agent::DistributedTracing::CrossAppMonitor.new(events)
        @distributed_tracing_monitor = NewRelic::Agent::DistributedTracing::Monitor.new(events)
      end
    end
  end
end
