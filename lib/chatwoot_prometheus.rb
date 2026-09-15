# frozen_string_literal: true

require 'prometheus/client'
require 'prometheus/client/formats/text'

module ChatwootPrometheus
  SNAPSHOT_GAUGES = {
    chatwoot_sidekiq_processed: 'Jobs processed since Sidekiq stats started',
    chatwoot_sidekiq_failed: 'Jobs failed since Sidekiq stats started',
    chatwoot_sidekiq_enqueued: 'Jobs waiting in queues',
    chatwoot_sidekiq_retry_size: 'Jobs in retry set',
    chatwoot_sidekiq_dead_size: 'Jobs in dead set',
    chatwoot_sidekiq_workers: 'Busy Sidekiq workers',
    chatwoot_sidekiq_queue_latency_seconds: 'Maximum Sidekiq queue latency in seconds'
  }.freeze

  class << self
    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PROMETHEUS', false))
    end

    def registry
      mutex.synchronize { @registry ||= build_registry }
    end

    def text
      mutex.synchronize do
        @registry ||= build_registry
        collect_sidekiq_locked
        Prometheus::Client::Formats::Text.marshal(@registry)
      end
    end

    def reset!
      mutex.synchronize do
        @registry = nil
        @snapshot_gauges = nil
        @scrape_success = nil
      end
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end

    def build_registry
      register = Prometheus::Client::Registry.new
      up = Prometheus::Client::Gauge.new(:chatwoot_up, docstring: '1 if the Chatwoot process is serving metrics')
      register.register(up)
      up.set(1)

      @scrape_success = Prometheus::Client::Gauge.new(
        :chatwoot_sidekiq_scrape_success,
        docstring: '1 if the last Sidekiq metrics scrape succeeded'
      )
      register.register(@scrape_success)
      @scrape_success.set(0)

      @snapshot_gauges = {}
      SNAPSHOT_GAUGES.each do |name, docstring|
        gauge = Prometheus::Client::Gauge.new(name, docstring: docstring)
        register.register(gauge)
        @snapshot_gauges[name] = gauge
      end

      register
    end

    def collect_sidekiq_locked
      stats = Sidekiq::Stats.new
      ensure_snapshot_gauges_locked
      @snapshot_gauges[:chatwoot_sidekiq_processed].set(stats.processed)
      @snapshot_gauges[:chatwoot_sidekiq_failed].set(stats.failed)
      @snapshot_gauges[:chatwoot_sidekiq_enqueued].set(stats.enqueued)
      @snapshot_gauges[:chatwoot_sidekiq_retry_size].set(stats.retry_size)
      @snapshot_gauges[:chatwoot_sidekiq_dead_size].set(stats.dead_size)
      @snapshot_gauges[:chatwoot_sidekiq_workers].set(stats.workers_size)
      @snapshot_gauges[:chatwoot_sidekiq_queue_latency_seconds].set(max_queue_latency)
      @scrape_success.set(1)
    rescue StandardError
      mark_sidekiq_scrape_failed
    end

    def max_queue_latency
      latencies = Sidekiq::Queue.all.map(&:latency)
      latencies.max || 0
    end

    def ensure_snapshot_gauges_locked
      return if @snapshot_gauges&.any? && SNAPSHOT_GAUGES.keys.all? { |name| registry_has?(name) }

      @snapshot_gauges = {}
      SNAPSHOT_GAUGES.each do |name, docstring|
        @registry.unregister(name) if registry_has?(name)
        gauge = Prometheus::Client::Gauge.new(name, docstring: docstring)
        @registry.register(gauge)
        @snapshot_gauges[name] = gauge
      end
    end

    def mark_sidekiq_scrape_failed
      SNAPSHOT_GAUGES.each_key { |name| @registry&.unregister(name) }
      @snapshot_gauges = {}
      @scrape_success&.set(0)
    end

    def registry_has?(name)
      @registry&.exist?(name)
    end
  end
end
