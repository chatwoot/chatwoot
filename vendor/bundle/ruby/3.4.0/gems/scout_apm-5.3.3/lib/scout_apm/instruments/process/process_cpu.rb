module ScoutApm
  module Instruments
    module Process
      class ProcessCpu
        attr_reader :num_processors
        attr_accessor :last_run, :last_utime, :last_stime
        attr_reader :context

        def initialize(context)
          @context = context

          @num_processors = [context.environment.processors, 1].compact.max

          t = ::Process.times
          @last_run = Time.now
          @last_utime = t.utime
          @last_stime = t.stime
        end

        def metric_type
          "CPU"
        end

        def metric_name
          "Utilization"
        end

        def human_name
          "Process CPU"
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

        # TODO: Figure out a good default instead of nil
        def run
          res = nil

          t = ::Process.times
          now = Time.now
          utime = t.utime
          stime = t.stime

          wall_clock_elapsed  = now - last_run
          if wall_clock_elapsed < 0
            save_times(now, utime, stime)
            logger.info "#{human_name}: Negative time elapsed.  now: #{now}, last_run: #{last_run}, total time: #{wall_clock_elapsed}."
            return nil
          end

          utime_elapsed   = utime - last_utime
          stime_elapsed   = stime - last_stime
          process_elapsed = utime_elapsed + stime_elapsed

          # This can happen right after a fork.  This class starts up in
          # pre-fork, records {u,s}time, then forks. This resets {u,s}time to 0
          if process_elapsed < 0
            save_times(now, utime, stime)
            logger.debug "#{human_name}: Negative process time elapsed.  utime: #{utime_elapsed}, stime: #{stime_elapsed}, total time: #{process_elapsed}. This is normal to see when starting a forking web server."
            return nil
          end

          # Normalized to # of processors
          normalized_wall_clock_elapsed = wall_clock_elapsed * num_processors

          # If somehow we run for 0 seconds between calls, don't try to divide by 0
          res = if normalized_wall_clock_elapsed == 0
                  0
                else
                  ( process_elapsed / normalized_wall_clock_elapsed )*100
                end

          if res < 0
            save_times(now, utime, stime)
            logger.info "#{human_name}: Negative CPU.  #{process_elapsed} / #{normalized_wall_clock_elapsed} * 100 ==> #{res}"
            return nil
          end

          save_times(now, utime, stime)

          logger.debug "#{human_name}: #{res.inspect} [#{num_processors} CPU(s)]"

          return res
        end

        def save_times(now, utime, stime)
          self.last_run = now
          self.last_utime = utime
          self.last_stime = stime
        end

        def logger
          context.logger
        end
      end
    end
  end
end
