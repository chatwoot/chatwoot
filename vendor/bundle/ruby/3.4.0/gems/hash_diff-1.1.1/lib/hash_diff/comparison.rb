module HashDiff
  class Comparison
    def initialize(left, right)
      @left  = left
      @right = right
    end

    attr_reader :left, :right

    def diff
      @diff ||= find_differences { |l, r| [l, r] }
    end

    def left_diff
      @left_diff ||= find_differences { |_, r| r }
    end

    def right_diff
      @right_diff ||= find_differences { |l, _| l }
    end

    protected

    def find_differences(&reporter)
      combined_keys.each_with_object({ }, &comparison_strategy(reporter))
    end

    private

    def comparison_strategy(reporter)
      lambda do |key, diff|
        diff[key] = report_difference(key, reporter) unless equal?(key)
      end
    end

    def combined_keys
      if hash?(left) && hash?(right) then
        (left.keys + right.keys).uniq
      elsif array?(left) && array?(right) then
        (0..[left.size, right.size].max).to_a
      else
        raise ArgumentError, "Don't know how to extract keys. Neither arrays nor hashes given"
      end
    end

    def equal?(key)
      value_with_default(left, key) == value_with_default(right, key)
    end

    def hash?(value)
      value.is_a?(Hash)
    end

    def array?(value)
      value.is_a?(Array)
    end

    def comparable_hash?(key)
      hash?(left[key]) && hash?(right[key])
    end

    def comparable_array?(key)
      array?(left[key]) && array?(right[key])
    end

    def report_difference(key, reporter)
      if comparable_hash?(key)
        self.class.new(left[key], right[key]).find_differences(&reporter)
      elsif comparable_array?(key)
        self.class.new(left[key], right[key]).find_differences(&reporter)
      else
        reporter.call(
          value_with_default(left, key),
          value_with_default(right, key)
        )
      end
    end

    def value_with_default(obj, key)
      obj.fetch(key, NO_VALUE)
    end
  end
end

