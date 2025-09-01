module WhapiErrorTracker
  # Simple error tracking helper for WHAPI operations
  def self.track_whapi_error(operation, error, context = {})
    Rails.logger.error "[WHAPI_ERROR] #{operation}: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if error.backtrace

    # Send to monitoring (Sentry, etc.) if configured
    Sentry.capture_exception(error, extra: context.merge(operation: operation)) if defined?(Sentry)

    # Add to custom error tracking if available
    return unless defined?(ExceptionTracker)

    ExceptionTracker.track_exception(error, operation: operation, context: context)
  end

  # Helper method for tracking errors with graceful degradation
  def self.track_and_degrade(operation, error, context = {})
    track_whapi_error(operation, error, context)

    # Return nil in production for non-critical operations, raise in development
    raise error unless Rails.env.production?

    Rails.logger.error "Gracefully degrading #{operation} in production"
    nil
  end
end
