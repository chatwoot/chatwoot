module ScoutApm
  class TransactionTimeConsumed
    # Private Accessor:
    # A hash of Endpoint Name to an time consumed record
    attr_reader :endpoints
    private :endpoints

    # Private Accessor:
    # The total time spent across all endpoints
    attr_reader :total_duration
    private :total_duration

    def initialize
      @total_duration = 0.0
      @endpoints = Hash.new { |h, k| h[k] = TotalTimeRecord.new }
    end

    def add(item, duration)
      @total_duration += duration.to_f
      @endpoints[item].add(duration.to_f)
    end

    def percent_of_total(item)
      if total_duration == 0.0
        0
      else
        @endpoints[item].total_duration / total_duration
      end
    end

    def total_time_for(item)
      @endpoints[item].total_duration
    end

    def call_count_for(item)
      @endpoints[item].count
    end

    # Time is in seconds
    TotalTimeRecord = Struct.new(:total_duration, :count) do
      def initialize
        super(0, 0)
      end

      def add(duration)
        self.total_duration += duration.to_f
        self.count += 1
      end
    end
  end
end
