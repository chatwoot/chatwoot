# frozen_string_literal: true

require "judoscale/metrics_collector"
require "judoscale/metrics_store"

module Judoscale
  class WebMetricsCollector < MetricsCollector
    def collect
      MetricsStore.instance.flush
    end
  end
end
