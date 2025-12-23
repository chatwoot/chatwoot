# Public API for the Scout Error Monitoring service
#
# See-Also ScoutApm::Transaction and ScoutApm::Tracing for APM related APIs
module ScoutApm
  module Error
    # Capture an exception, optionally with an environment hash. This may be a
    # Rack environment, but is not required.
    def self.capture(exception, env={})
      context = ScoutApm::Agent.instance.context

      # Skip if error monitoring isn't enabled at all
      if ! context.config.value("errors_enabled")
        return false
      end

      # Skip if this one error is ignored
      if context.ignored_exceptions.ignored?(exception)
        return false
      end

      # Capture the error for further processing and shipping
      context.error_buffer.capture(exception, env)

      return true
    end
  end
end
