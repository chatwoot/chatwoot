# frozen_string_literal: true

require "set"
require "judoscale/metrics_collector"
require "judoscale/logger"

module Judoscale
  class JobMetricsCollector < MetricsCollector
    include Judoscale::Logger

    def self.collect?(config)
      super && !config.current_runtime_container.redundant_instance? && adapter_config.enabled
    end

    def self.adapter_name
      @_adapter_name ||= adapter_identifier.to_s.capitalize.gsub(/(?:_)(.)/i) { $1.upcase }
    end

    def self.adapter_identifier
      adapter_config.identifier
    end

    def self.adapter_config
      raise "Implement `self.adapter_config` in individual job metrics collectors."
    end

    def initialize
      super

      log_msg = +"#{self.class.adapter_name} enabled"
      log_msg << " with busy job tracking support" if track_busy_jobs?
      logger.info log_msg
    end

    # Track the known queues so we can continue reporting on queues that don't
    # have enqueued jobs at the time of reporting.
    def queues
      @queues ||= Set.new([])
    end

    def queues=(new_queues)
      @queues = filter_queues(new_queues)
    end

    def clear_queues
      @queues = nil
    end

    private

    def adapter_config
      self.class.adapter_config
    end

    def filter_queues(queues)
      configured_queues = adapter_config.queues

      if configured_queues.empty?
        configured_filter = adapter_config.queue_filter

        if configured_filter.respond_to?(:call)
          queues = queues.select { |queue| configured_filter.call(queue) }
        end
      else
        queues = configured_queues
      end

      queues = filter_max_queues(queues)

      Set.new(queues)
    end

    # Collect up to the configured `max_queues`, skipping the rest.
    # We sort queues by name length before making the cut-off, as a simple heuristic to keep the shorter ones
    # and possibly ignore the longer ones, which are more likely to be dynamically generated for example.
    def filter_max_queues(queues_to_collect)
      queues_size = queues_to_collect.size
      max_queues = adapter_config.max_queues

      if queues_size > max_queues
        logger.warn "#{self.class.adapter_name} metrics reporting only #{max_queues} queues max, skipping the rest (#{queues_size - max_queues})"
        queues_to_collect.sort_by(&:length).first(max_queues)
      else
        queues_to_collect
      end
    end

    # Sample log line for each collection, assuming `sidekiq` as the adapter identifier:
    #   `sidekiq-qt.default=10ms sidekiq-qd.default=3 sidekiq-busy.default=1`
    def log_collection(metrics)
      return if metrics.empty?

      identifier = self.class.adapter_identifier
      messages = metrics.map { |metric|
        "#{identifier}-#{metric.identifier}.#{metric.queue_name}=#{metric.value}#{"ms" if metric.identifier == :qt}"
      }
      logger.debug messages.join(" ")
    end

    def track_busy_jobs?
      adapter_config.track_busy_jobs
    end
  end
end
