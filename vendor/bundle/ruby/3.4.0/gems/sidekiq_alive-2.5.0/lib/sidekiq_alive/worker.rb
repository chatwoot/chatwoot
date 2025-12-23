# frozen_string_literal: true

module SidekiqAlive
  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false

    # Passing the hostname argument it's only for debugging enqueued jobs
    def perform(_hostname = SidekiqAlive.hostname)
      # Checks if custom liveness probe passes should fail or return false
      return unless config.custom_liveness_probe.call

      # Writes the liveness in Redis
      write_living_probe
      remove_orphaned_queues
      # schedules next living probe
      self.class.perform_in(config.worker_interval, current_hostname)
    end

    def write_living_probe
      # Write liveness probe
      SidekiqAlive.store_alive_key
      # Increment ttl for current registered instance
      SidekiqAlive.register_current_instance
      # after callbacks
      begin
        config.callback.call
      rescue StandardError
        nil
      end
    end

    # Removes orphaned Sidekiq queues left behind by unexpected instance shutdowns (e.g., due to OOM)
    def remove_orphaned_queues
      # If the worker isn't executed within this window, the lifeness key expires
      latency_threshold = config.time_to_live - config.worker_interval
      Sidekiq::Queue.all
        .filter { |q| q.name.start_with?(config.queue_prefix.to_s) }
        .filter { |q| q.latency > latency_threshold }
        .filter { |q| q.size == 1 && q.all? { |job| job.klass == self.class.name } }
        .each(&:clear)
    end

    def current_hostname
      SidekiqAlive.hostname
    end

    def config
      SidekiqAlive.config
    end
  end
end
