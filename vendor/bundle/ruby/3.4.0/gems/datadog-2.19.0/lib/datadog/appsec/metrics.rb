# frozen_string_literal: true

module Datadog
  module AppSec
    # This namespace contains classes related to metrics collection and exportation.
    module Metrics
    end
  end
end

require_relative 'metrics/collector'
require_relative 'metrics/exporter'
require_relative 'metrics/telemetry'
