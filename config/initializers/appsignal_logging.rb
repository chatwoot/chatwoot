# Send application logs to AppSignal while preserving existing logging behavior.
# Requires APPSIGNAL_PUSH_API_KEY to be set (already configured in K8s deploy).
if defined?(Appsignal)
  appsignal_logger = Appsignal::Logger.new('rails')

  # Broadcast to existing Rails logger so stdout/file logging still works
  appsignal_logger.broadcast_to(Rails.logger)

  Rails.logger = ActiveSupport::TaggedLogging.new(appsignal_logger)
end
