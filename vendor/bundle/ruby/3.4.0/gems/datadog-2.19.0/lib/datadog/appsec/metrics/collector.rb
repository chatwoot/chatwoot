# frozen_string_literal: true

module Datadog
  module AppSec
    module Metrics
      # A class responsible for collecting WAF and RASP call metrics.
      class Collector
        Store = Struct.new(:evals, :timeouts, :duration_ns, :duration_ext_ns, keyword_init: true)

        attr_reader :waf, :rasp

        def initialize
          @mutex = Mutex.new
          @waf = Store.new(evals: 0, timeouts: 0, duration_ns: 0, duration_ext_ns: 0)
          @rasp = Store.new(evals: 0, timeouts: 0, duration_ns: 0, duration_ext_ns: 0)
        end

        def record_waf(result)
          @mutex.synchronize do
            @waf.evals += 1
            @waf.timeouts += 1 if result.timeout?
            @waf.duration_ns += result.duration_ns
            @waf.duration_ext_ns += result.duration_ext_ns
          end
        end

        def record_rasp(result)
          @mutex.synchronize do
            @rasp.evals += 1
            @rasp.timeouts += 1 if result.timeout?
            @rasp.duration_ns += result.duration_ns
            @rasp.duration_ext_ns += result.duration_ext_ns
          end
        end
      end
    end
  end
end
