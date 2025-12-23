module ScoutApm
  class Middleware
    MAX_ATTEMPTS = 5

    def initialize(app)
      @app = app
      @attempts = 0
      # @enabled = ScoutApm::Agent.instance.context.apm_enabled?
      # XXX: Figure out if this middleware should even know
      @enabled = true
      @started = ScoutApm::Agent.instance.context.started? && ScoutApm::Agent.instance.background_worker_running?
    end

    # If we get a web request in, then we know we're running in some sort of app server
    def call(env)
      if !@enabled || @started || @attempts > MAX_ATTEMPTS
        @app.call(env)
      else
        attempt_to_start_agent
        @app.call(env)
      end
    end

    def attempt_to_start_agent
      @attempts += 1
      ScoutApm::Agent.instance.start
      @started = ScoutApm::Agent.instance.context.started? && ScoutApm::Agent.instance.background_worker_running?
    rescue => e
      ScoutApm::Agent.instance.context.logger.info("Failed to start via Middleware: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    end
  end
end
