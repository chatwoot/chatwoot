module ScoutApm
  class ExternalServiceMetricStats

    DEFAULT_HISTOGRAM_SIZE = 50

    attr_reader :domain_name
    attr_reader :operation
    attr_reader :scope

    attr_reader :transaction_count

    attr_reader :call_count
    attr_reader :call_time

    attr_reader :min_call_time
    attr_reader :max_call_time

    attr_reader :histogram

    def initialize(domain_name, operation, scope, call_count, call_time)
      @domain_name = domain_name
      @operation = operation

      @call_count = call_count

      @call_time = call_time
      @min_call_time = call_time
      @max_call_time = call_time

      # This histogram is for call_time
      @histogram = NumericHistogram.new(DEFAULT_HISTOGRAM_SIZE)
      @histogram.add(call_time)

      @transaction_count = 0

      @scope = scope
    end

    # Merge data in this scope. Used in ExternalServiceMetricSet
    def key
      @key ||= [domain_name, operation, scope]
    end

    # Combine data from another ExternalServiceMetricStats into +self+. Modifies and returns +self+
    def combine!(other)
      return self if other == self

      @transaction_count += other.transaction_count
      @call_count += other.call_count
      @call_time += other.call_time

      @min_call_time = other.min_call_time if @min_call_time.zero? or other.min_call_time < @min_call_time
      @max_call_time = other.max_call_time if other.max_call_time > @max_call_time

      @histogram.combine!(other.histogram)
      self
    end

    def as_json
      json_attributes = [
        :domain_name,
        :operation,
        :scope,

        :transaction_count,
        :call_count,

        :histogram,
        :call_time,
        :max_call_time,
        :min_call_time,
      ]

      ScoutApm::AttributeArranger.call(self, json_attributes)
    end

    # Called by the Set on each ExternalServiceMetricStats object that it holds, only
    # once during the recording of a transaction.
    #
    # Don't call elsewhere, and don't set to 1 in the initializer.
    def increment_transaction_count!
      @transaction_count += 1
    end
  end
end
