# A note on GAUGE_COUNTERS.
#
# The sample_rate argument allows for the parameterization
# of instruments that decide to report data as gauges, that
# would typically be reported as counters.
#
# Aggregating counters is typically done simply with the `+`
# operator, which doesn't preserve the number of unique
# reporters that contributed to the count, or allow for one
# to learn the *average* of the counts posted.
#
# A gauge is typically aggregated by simply *replacing* the
# previous value, however, some systems do *more* with gauges
# when aggregating across multiple sources of that gauge, like,
# average, or compute stdev.
#
# This is problematic, however, when a gauge is being used as
# a counter, to preserve the average / stdev computational
# properties from above, because the interval that the gauge
# is being read it, affects the derivative of the increasing
# count. Instead of the derivative over 60s, the derivative is
# taken every 10s, giving us a derivative value that's approximately
# 1/6th of the actual derivative over 60s.
#
# We compensate for this by allowing Instruments to correct for
# this, and ensure that, even though it's an estimate, the data
# is scaled appropriately to the target aggregation interval, not
# just the collection interval.

module Barnes
  module Instruments
    class RubyGC
      COUNTERS = {
        :count => :'GC.count',
        :major_gc_count => :'GC.major_count',
        :minor_gc_count => :'GC.minor_gc_count' }

      GAUGE_COUNTERS = {}

      # Detect Ruby 2.1 vs 2.2 GC.stat naming
      begin
        GC.stat :total_allocated_objects
      rescue ArgumentError
        GAUGE_COUNTERS.update \
          :total_allocated_object => :'GC.total_allocated_objects',
          :total_freed_object => :'GC.total_freed_objects'
      else
        GAUGE_COUNTERS.update \
          :total_allocated_objects => :'GC.total_allocated_objects',
          :total_freed_objects => :'GC.total_freed_objects'
      end

      def initialize(sample_rate)
        # see header for an explanation of how this sample_rate is used
        @sample_rate = sample_rate
      end

      def start!(state)
        state[:ruby_gc] = GC.stat
      end

      def instrument!(state, counters, gauges)
        last = state[:ruby_gc]
        cur = state[:ruby_gc] = GC.stat

        COUNTERS.each do |stat, metric|
          counters[metric] = cur[stat] - last[stat] if cur.include? stat
        end

        # special treatment gauges
        GAUGE_COUNTERS.each do |stat, metric|
          if cur.include? stat
            val = cur[stat] - last[stat] if cur.include? stat
            gauges[metric] = val * (1/@sample_rate)
          end
        end

        # the rest of the gauges
        cur.each do |k, v|
          unless GAUGE_COUNTERS.include? k
            gauges[:"GC.#{k}"] = v
          end
        end
      end
    end
  end
end
