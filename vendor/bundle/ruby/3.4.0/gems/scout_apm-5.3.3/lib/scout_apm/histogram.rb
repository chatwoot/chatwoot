module ScoutApm
  HistogramBin = Struct.new(:value, :count)

  class NumericHistogram
    # This class should be threadsafe.
    attr_reader :mutex

    attr_reader :max_bins
    attr_reader :bins
    attr_accessor :total

    def marshal_dump
      [@max_bins, @bins, @total]
    end

    def marshal_load(array)
      @max_bins, @bins, @total = array
      @mutex = Mutex.new
    end

    def initialize(max_bins)
      @max_bins = max_bins
      @bins = []
      @total = 0
      @mutex = Mutex.new
    end

    def add(new_value)
      mutex.synchronize do
        @total += 1
        create_new_bin(new_value.to_f)
        trim
      end
    end

    def quantile(q)
      mutex.synchronize do
        return 0 if total == 0

        if q > 1
          q = q / 100.0
        end

        count = q.to_f * total.to_f

        bins.each_with_index do |bin, index|
          count -= bin.count

          if count <= 0
            return bin.value
          end
        end

        # If we fell through, we were asking for the last (max) value
        return bins[-1].value
      end
    end

    # Given a value, where in this histogram does it fall?
    # Returns a float between 0 and 1
    def approximate_quantile_of_value(v)
      mutex.synchronize do
        return 100 if total == 0

        count_examined = 0

        bins.each_with_index do |bin, index|
          if v <= bin.value
            break
          end

          count_examined += bin.count
        end

        count_examined / total.to_f
      end
    end

    def mean
      mutex.synchronize do
        if total == 0
          return 0
        end

        sum = bins.inject(0) { |s, bin| s + (bin.value * bin.count) }
        return sum.to_f / total.to_f
      end
    end

    def combine!(other)
      mutex.synchronize do
        other.mutex.synchronize do
          @bins = (other.bins + @bins).
            group_by {|b| b.value }.
            map {|val, bs| [val, bs.inject(0) {|sum, b| sum + b.count }] }.
            map {|val, sum| HistogramBin.new(val,sum) }.
            sort_by { |b| b.value }
          @total += other.total
          trim
          self
        end
      end
    end

    def as_json
      mutex.synchronize do
        bins.map{ |b|
          [
            ScoutApm::Utils::Numbers.round(b.value, 4),
            b.count
          ]
        }
      end
    end

    private

    # If we exactly match an existing bin, add to it, otherwise create a new bin holding a count for the new value.
    def create_new_bin(new_value)
      bins.each_with_index do |bin, index|
        # If it matches exactly, increment the bin's count
        if bin.value == new_value
          bin.count += 1
          return
        end

        # We've gone one bin too far, so insert before the current bin.
        if bin.value > new_value
          # Insert at this index
          new_bin = HistogramBin.new(new_value, 1)
          bins.insert(index, new_bin)
          return
        end
      end

      # If we get to here, the bin needs to be added to the end.
      bins << HistogramBin.new(new_value, 1)
    end

    def trim
      while bins.length > max_bins
        trim_one
      end
    end

    def trim_one
      minDelta = Float::MAX
      minDeltaIndex = 0

      # Which two bins should we merge?
      bins.each_with_index do |_, index|
        next if index == 0

        delta = bins[index].value - bins[index - 1].value
        if delta < minDelta
          minDelta = delta
          minDeltaIndex = index
        end
      end

      # Create the merged bin with summed count, and weighted value
      mergedCount = bins[minDeltaIndex - 1].count + bins[minDeltaIndex].count
      mergedValue = (
        bins[minDeltaIndex - 1].value * bins[minDeltaIndex - 1].count +
        bins[minDeltaIndex].value     * bins[minDeltaIndex].count
        ) / mergedCount

      mergedBin = HistogramBin.new(mergedValue, mergedCount)

      # Remove the two bins we just merged together, then add the merged one
      bins.slice!(minDeltaIndex - 1, 2)
      bins.insert(minDeltaIndex - 1, mergedBin)
    rescue => e
      ScoutApm::Agent.instance.context.logger.info("Error in NumericHistogram#trim_one. #{e.message}, #{e.backtrace}, #{self.inspect}")
      raise
    end
  end
end
