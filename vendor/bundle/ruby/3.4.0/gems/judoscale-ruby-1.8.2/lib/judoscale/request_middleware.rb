# frozen_string_literal: true

require "judoscale/metrics_store"
require "judoscale/reporter"
require "judoscale/logger"
require "judoscale/request_metrics"

module Judoscale
  class RequestMiddleware
    include Logger

    def initialize(app)
      @app = app
    end

    def call(env)
      request_metrics = RequestMetrics.new(env)

      unless request_metrics.ignore?
        queue_time = request_metrics.queue_time
        network_time = request_metrics.network_time
      end

      Reporter.start

      if queue_time
        store = MetricsStore.instance

        # NOTE: Expose queue time to the app
        env["judoscale.queue_time"] = queue_time
        store.push :qt, queue_time

        unless network_time.zero?
          env["judoscale.network_time"] = network_time
          store.push :nt, network_time
        end

        logger.debug "Request queue_time=#{queue_time}ms network_time=#{network_time}ms request_id=#{request_metrics.request_id} size=#{request_metrics.size}"
      end

      @app.call(env)
    end
  end
end
