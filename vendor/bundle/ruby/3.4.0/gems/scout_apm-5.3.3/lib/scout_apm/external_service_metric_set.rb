# Note, this class must be Marshal Dumpable
module ScoutApm
  class ExternalServiceMetricSet
    include Enumerable

    attr_reader :metrics # the raw metrics. You probably want #metrics_to_report

    def marshal_dump
      [ @metrics ]
    end

    def marshal_load(array)
      @metrics = array.first
      @context = ScoutApm::Agent.instance.context
    end

    def initialize(context)
      @context = context

      # A hash of ExternalServiceMetricStats values, keyed by ExternalServiceMetricStats.key
      @metrics = Hash.new
    end

    # Need to look this up again if we end up as nil. Which I guess can happen
    # after a Marshal load?
    def context
      @context ||= ScoutApm::Agent.instance.context
    end

    def each
      metrics.each do |_key, external_service_metric_stat|
        yield external_service_metric_stat
      end
    end

    # Looks up a ExternalServiceMetricStats instance in the +@metrics+ hash. Sets the value to +other+ if no key
    # Returns a ExternalServiceMetricStats instance
    def lookup(other)
      metrics[other.key] ||= other
    end

    # Take another set, and merge it with this one
    def combine!(other)
      other.each do |metric|
        self << metric
      end
      self
    end

    # Add a single ExternalServiceMetricStats object to this set.
    #
    # Looks up an existing one under this key and merges, or just saves a new
    # one under the key
    def <<(stat)
      existing_stat = metrics[stat.key]
      if existing_stat
        existing_stat.combine!(stat)
      elsif at_limit?
        # We're full up, can't add any more.
        # Should I log this? It may get super noisy?
      else
        metrics[stat.key] = stat
      end
    end

    def increment_transaction_count!
      metrics.each do |_key, external_service_metric_stat|
        external_service_metric_stat.increment_transaction_count!
      end
    end

    def metrics_to_report
      report_limit = context.config.value('external_service_metric_report_limit')
      if metrics.size > report_limit
        metrics.
          values.
          sort_by {|stat| stat.call_time }.
          reverse.
          take(report_limit)
      else
        metrics.values
      end
    end

    def inspect
      metrics.map {|key, metric|
        "#{key.inspect} - Count: #{metric.call_count}, Total Time: #{"%.2f" % metric.call_time}"
      }.join("\n")
    end

    def at_limit?
      @limit ||= context.config.value('external_service_metric_limit')
      metrics.size >= @limit
    end

  end
end
