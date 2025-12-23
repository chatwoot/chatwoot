module ScoutApm
  module Instruments
    module Process
      class ProcessMemory
        # Account for Darwin returning maxrss in bytes and Linux in KB. Used by
        # the slow converters. Doesn't feel like this should go here
        # though...more of a utility.
        def rss_to_mb(rss)
          kilobyte_adjust = @context.environment.os == 'darwin' ? 1024 : 1
          rss.to_f / 1024 / kilobyte_adjust
        end

        def rss
          ::Process.rusage.maxrss
        end

        def rss_in_mb
          rss_to_mb(rss)
        end

        def initialize(context)
          @context = context
        end

        def metric_type
          "Memory"
        end

        def metric_name
          "Physical"
        end

        def human_name
          "Process Memory"
        end

        def metrics(timestamp, store)
          result = run
          if result
            meta = MetricMeta.new("#{metric_type}/#{metric_name}")
            stat = MetricStats.new(false)
            stat.update!(result)
            store.track!({ meta => stat }, :timestamp => timestamp)
          else
            {}
          end
        end

        def run
          rss_in_mb.tap { |res| logger.debug "#{human_name}: #{res.inspect}" }
        end

        def logger
          @context.logger
        end
      end
    end
  end
end
