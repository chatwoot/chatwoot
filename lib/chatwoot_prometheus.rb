# frozen_string_literal: true

require 'prometheus/client'
require 'prometheus/client/formats/text'

# Opt-in Prometheus registry for self-hosted operators (ENABLE_PROMETHEUS=true).
# Process metrics are cheap. Sidekiq gauges are collected at scrape time and
# skipped if Redis is unavailable.
module ChatwootPrometheus
  class << self
    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PROMETHEUS', false))
    end

    def registry
      @registry ||= build_registry
    end

    def text
      collect_sidekiq
      Prometheus::Client::Formats::Text.marshal(registry)
    end

    def reset!
      @registry = nil
      @sidekiq_gauges = nil
    end

    private

    def build_registry
      register = Prometheus::Client::Registry.new
      up = Prometheus::Client::Gauge.new(:chatwoot_up, docstring: '1 if the Chatwoot process is serving metrics')
      register.register(up)
      up.set(1)
      register
    end

    def collect_sidekiq
      return unless defined?(Sidekiq)

      stats = Sidekiq::Stats.new
      gauge(:chatwoot_sidekiq_processed_total, 'Jobs processed since Sidekiq start').set(stats.processed)
      gauge(:chatwoot_sidekiq_failed_total, 'Jobs failed since Sidekiq start').set(stats.failed)
      gauge(:chatwoot_sidekiq_enqueued, 'Jobs waiting in queues').set(stats.enqueued)
      gauge(:chatwoot_sidekiq_retry_size, 'Jobs in retry set').set(stats.retry_size)
      gauge(:chatwoot_sidekiq_dead_size, 'Jobs in dead set').set(stats.dead_size)
      gauge(:chatwoot_sidekiq_workers, 'Busy Sidekiq workers').set(stats.workers_size)
    rescue StandardError
      nil
    end

    def gauge(name, docstring)
      @sidekiq_gauges ||= {}
      @sidekiq_gauges[name] ||= begin
        g = Prometheus::Client::Gauge.new(name, docstring: docstring)
        registry.register(g)
        g
      end
    end
  end
end
