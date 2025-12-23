# Used to run a given task every 60 seconds.
module ScoutApm
  class BackgroundWorker
    # in seconds, time between when the worker thread wakes up and runs.
    DEFAULT_PERIOD = 60

    attr_reader :period

    attr_reader :context

    def initialize(context, period=DEFAULT_PERIOD)
      @context = context
      @period = period
      @keep_running = true
    end

    def logger
      context.logger
    end

    def running?
      @keep_running
    end

    def stop
      logger.debug "Background Worker: stop requested"
      @keep_running = false
    end

    # Runs the task passed to +start+ once.
    def run_once
      @task.call if @task
    end

    # Starts running the passed block every 60 seconds (starting now).
    def start(&block)
      @task = block

      logger.debug "Background Worker: starting to run every #{period} seconds"

      # The first run should be 1 period of time from now
      next_time = Time.now + period

      loop do
        begin
          now = Time.now

          # Sleep the correct amount of time to reach next_time
          while now < next_time && @keep_running
            sleep_time = next_time - now
            sleep(sleep_time) if sleep_time > 0
            now = Time.now
          end

          # Bail out if @keep_running is false
          unless @keep_running
            logger.debug "Background Worker: breaking from loop"
            break
          end

          @task.call

          # Adjust the next time to run forward by @periods until it is in the future
          while next_time <= now
            next_time += period
          end
        rescue
          logger.debug "Background Worker Exception!"
          logger.debug $!.message
          logger.debug $!.backtrace
        end
      end
    end
  end
end
