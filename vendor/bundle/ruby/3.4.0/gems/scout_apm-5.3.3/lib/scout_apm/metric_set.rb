module ScoutApm
  class MetricSet
    # We can't aggregate a handful of things like samplers (CPU, Memory), or
    # Controller, and Percentiles so pass through these metrics directly
    #
    # TODO: Figure out a way to not have this duplicate what's in Samplers, and also on server's ingest
    PASSTHROUGH_METRICS = ["CPU", "Memory", "Instance", "Controller", "SlowTransaction", "Percentile", "Job"]

    attr_reader :metrics

    def initialize
      @metrics = Hash.new
    end

    def absorb_all(metrics)
      Array(metrics).each { |m| absorb(m) }
    end

    # Absorbs a single new metric into the aggregates
    def absorb(metric)
      meta, stat = metric

      if PASSTHROUGH_METRICS.include?(meta.type) # Leave as-is, don't attempt to combine into an /all key
        @metrics[meta] ||= MetricStats.new
        @metrics[meta].combine!(stat)

      elsif meta.type == "Errors" # Sadly special cased, we want both raw and aggregate values
        # When combining MetricSets between different 
          @metrics[meta] ||= MetricStats.new
          @metrics[meta].combine!(stat)

        if !@combine_in_progress
          agg_meta = MetricMeta.new("Errors/Request", :scope => meta.scope)
          @metrics[agg_meta] ||= MetricStats.new
          @metrics[agg_meta].combine!(stat)
        end

      else # Combine down to a single /all key
        agg_meta = MetricMeta.new("#{meta.type}/all", :scope => meta.scope)
        @metrics[agg_meta] ||= MetricStats.new
        @metrics[agg_meta].combine!(stat)
      end
    end

    # Sets a combine_in_progress flag to prevent double-counting Error metrics.
    # Without it, the Errors/Request number would be increasingly off as
    # metric_sets get merged in.
    def combine!(other)
      @combine_in_progress = true
      absorb_all(other.metrics)
      @combine_in_progress = false
      self
    end


    def eql?(other)
      metrics == other.metrics
    end
    alias :== :eql?
  end
end
