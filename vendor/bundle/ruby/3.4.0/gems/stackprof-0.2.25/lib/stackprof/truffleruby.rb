module StackProf
  # Define the same methods as stackprof.c
  class << self
    def running?
      false
    end

    def run(*args)
      unimplemented
    end

    def start(*args)
      unimplemented
    end

    def stop
      unimplemented
    end

    def results(*args)
      unimplemented
    end

    def sample
      unimplemented
    end

    def use_postponed_job!
      # noop
    end

    private def unimplemented
      raise "Use --cpusampler=flamegraph or --cpusampler instead of StackProf on TruffleRuby.\n" \
            "See https://www.graalvm.org/tools/profiling/ and `ruby --help:cpusampler` for more details."
    end
  end
end
