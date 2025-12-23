# frozen_string_literal: true

module Sentry
  class BackpressureMonitor < ThreadedPeriodicWorker
    DEFAULT_INTERVAL = 10
    MAX_DOWNSAMPLE_FACTOR = 10

    def initialize(configuration, client, interval: DEFAULT_INTERVAL)
      super(configuration.logger, interval)
      @client = client

      @healthy = true
      @downsample_factor = 0
    end

    def healthy?
      ensure_thread
      @healthy
    end

    def downsample_factor
      ensure_thread
      @downsample_factor
    end

    def run
      check_health
      set_downsample_factor
    end

    def check_health
      @healthy = !(@client.transport.any_rate_limited? || Sentry.background_worker&.full?)
    end

    def set_downsample_factor
      if @healthy
        log_debug("[BackpressureMonitor] health check positive, reverting to normal sampling") if @downsample_factor.positive?
        @downsample_factor = 0
      else
        @downsample_factor += 1 if @downsample_factor < MAX_DOWNSAMPLE_FACTOR
        log_debug("[BackpressureMonitor] health check negative, downsampling with a factor of #{@downsample_factor}")
      end
    end
  end
end
