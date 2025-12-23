class Statsd
  # = MonotonicTime: a helper for getting monotonic time
  #
  # @example
  #   MonotonicTime.time_in_ms #=> 287138801.144576

  # MonotonicTime guarantees that the time is strictly linearly
  # increasing (unlike realtime).
  # @see http://pubs.opengroup.org/onlinepubs/9699919799/functions/clock_getres.html
  module MonotonicTime
    class << self
      # @return [Integer] current monotonic time in milliseconds
      def time_in_ms
        time_in_nanoseconds / (10.0 ** 6)
      end

      private

      if defined?(Process::CLOCK_MONOTONIC)
        def time_in_nanoseconds
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
        end
      elsif RUBY_ENGINE == 'jruby'
        def time_in_nanoseconds
          java.lang.System.nanoTime
        end
      else
        def time_in_nanoseconds
          t = Time.now
          t.to_i * (10 ** 9) + t.nsec
        end
      end
    end
  end
end
