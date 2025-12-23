# frozen_string_literal: true

require 'barnes/instruments/puma_stats_value'
module Barnes
  module Instruments
    class PumaInstrument
      def initialize(sample_rate=nil)
        @debug = ENV["BARNES_DEBUG_PUMA_STATS"]
        @puma_has_stats = (defined?(::Puma) && ::Puma.respond_to?(:stats))
      end

      def valid?
        return false unless defined?(Puma)
        return false unless ENV["DYNO"] && ENV["DYNO"].start_with?("web")
        true
      end

      def start!(state)
        require 'multi_json'
      end

      def json_stats
        return {} unless @puma_has_stats
        MultiJson.load(::Puma.stats || "{}")

      # Puma loader has not been initialized yet
      rescue NoMethodError => e
        raise e unless e.message =~ /nil/
        return {}
      end

      def instrument!(state, counters, gauges)
        gauges['using.puma'] = 1

        stats = json_stats
        return if stats.empty?

        puts "Puma debug stats from barnes: #{stats}" if @debug

        pool_capacity = StatValue.new(stats, "pool_capacity").value
        max_threads   = StatValue.new(stats, "max_threads").value
        spawned       = StatValue.new(stats, "running").value

        gauges[:'pool.capacity']    = pool_capacity if pool_capacity
        gauges[:'threads.max']      = max_threads   if max_threads
        gauges[:'threads.spawned']  = spawned       if spawned
      end
    end
  end
end
