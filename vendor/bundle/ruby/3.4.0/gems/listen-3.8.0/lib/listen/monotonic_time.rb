# frozen_string_literal: true

module Listen
  module MonotonicTime
    class << self
      if defined?(Process::CLOCK_MONOTONIC)

        def now
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

      elsif defined?(Process::CLOCK_MONOTONIC_RAW)

        def now
          Process.clock_gettime(Process::CLOCK_MONOTONIC_RAW)
        end

      else

        def now
          Time.now.to_f
        end

      end
    end
  end
end
