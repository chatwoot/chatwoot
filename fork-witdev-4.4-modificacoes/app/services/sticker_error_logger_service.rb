class StickerErrorLoggerService
  CRITICAL_ERRORS = %w[
    GIPHY_API_KEY_MISSING
    WHATSAPP_AUTH_ERROR
    STORAGE_ERROR
    UNKNOWN_ERROR
  ].freeze

  HIGH_PRIORITY_ERRORS = %w[
    GIPHY_UNAVAILABLE
    WHATSAPP_API_ERROR
    MEDIA_UPLOAD_FAILED
    VALIDATION_ERROR
  ].freeze

  def self.log_error(error_code:, error_message:, context: {}, user: nil, account: nil)
    new.log_error(
      error_code: error_code,
      error_message: error_message,
      context: context,
      user: user,
      account: account
    )
  end

  def log_error(error_code:, error_message:, context: {}, user: nil, account: nil)
    severity = determine_severity(error_code)
    
    log_data = {
      timestamp: Time.current.iso8601,
      error_code: error_code,
      error_message: error_message,
      severity: severity,
      context: sanitize_context(context),
      user_id: user&.id,
      account_id: account&.id,
      feature: 'sticker_library'
    }

    # Log to Rails logger with appropriate level
    case severity
    when 'critical'
      Rails.logger.error("[STICKER_CRITICAL] #{log_data.to_json}")
    when 'high'
      Rails.logger.warn("[STICKER_HIGH] #{log_data.to_json}")
    else
      Rails.logger.info("[STICKER_INFO] #{log_data.to_json}")
    end

    # Increment error metrics for monitoring
    increment_error_metrics(error_code, severity)

    # Send alerts for critical errors
    send_alert_if_needed(severity, log_data) if should_send_alerts?

    log_data
  end

  private

  def determine_severity(error_code)
    return 'critical' if CRITICAL_ERRORS.include?(error_code)
    return 'high' if HIGH_PRIORITY_ERRORS.include?(error_code)
    'medium'
  end

  def sanitize_context(context)
    # Remove sensitive information from context
    sanitized = context.dup
    
    # Remove sensitive keys
    sensitive_keys = %w[api_key token password secret auth_token]
    sensitive_keys.each do |key|
      sanitized.delete(key)
      sanitized.delete(key.to_sym)
    end

    # Truncate long values
    sanitized.each do |key, value|
      if value.is_a?(String) && value.length > 1000
        sanitized[key] = "#{value[0..997]}..."
      end
    end

    sanitized
  end

  def increment_error_metrics(error_code, severity)
    # Increment general error counter
    Rails.cache.increment("sticker_errors_total", 1, expires_in: 1.hour)
    
    # Increment specific error counter
    Rails.cache.increment("sticker_error_#{error_code.downcase}", 1, expires_in: 1.hour)
    
    # Increment severity counter
    Rails.cache.increment("sticker_errors_#{severity}", 1, expires_in: 1.hour)
  rescue StandardError => e
    Rails.logger.warn("Failed to increment error metrics: #{e.message}")
  end

  def should_send_alerts?
    # Only send alerts in production or when explicitly enabled
    Rails.env.production? || ENV['STICKER_ALERTS_ENABLED'] == 'true'
  end

  def send_alert_if_needed(severity, log_data)
    return unless severity == 'critical'

    # Check if we've already sent an alert for this error recently
    alert_key = "sticker_alert_#{log_data[:error_code]}_#{log_data[:account_id]}"
    return if Rails.cache.exist?(alert_key)

    # Set alert cooldown (don't spam alerts)
    Rails.cache.write(alert_key, true, expires_in: 30.minutes)

    # Send alert (implement based on your alerting system)
    send_critical_alert(log_data)
  end

  def send_critical_alert(log_data)
    # Implement your alerting mechanism here
    # Examples: Slack webhook, email, PagerDuty, etc.
    
    alert_message = build_alert_message(log_data)
    
    # Example: Log critical alert (replace with actual alerting)
    Rails.logger.error("[STICKER_ALERT] #{alert_message}")
    
    # Example: Send to external monitoring service
    # ExternalMonitoringService.send_alert(alert_message) if defined?(ExternalMonitoringService)
  end

  def build_alert_message(log_data)
    {
      title: "Critical Sticker Library Error",
      message: "Error Code: #{log_data[:error_code]}\nMessage: #{log_data[:error_message]}",
      account_id: log_data[:account_id],
      user_id: log_data[:user_id],
      timestamp: log_data[:timestamp],
      context: log_data[:context]
    }.to_json
  end

  # Class methods for retrieving error statistics
  def self.error_stats(time_period: 1.hour)
    {
      total_errors: Rails.cache.read("sticker_errors_total") || 0,
      critical_errors: Rails.cache.read("sticker_errors_critical") || 0,
      high_priority_errors: Rails.cache.read("sticker_errors_high") || 0,
      medium_priority_errors: Rails.cache.read("sticker_errors_medium") || 0,
      error_breakdown: error_breakdown,
      time_period: time_period
    }
  end

  def self.error_breakdown
    breakdown = {}
    
    # Get counts for specific error codes
    (CRITICAL_ERRORS + HIGH_PRIORITY_ERRORS).each do |error_code|
      count = Rails.cache.read("sticker_error_#{error_code.downcase}") || 0
      breakdown[error_code] = count if count > 0
    end
    
    breakdown
  end

  def self.reset_error_stats
    # Clear all error metrics (useful for testing or manual reset)
    Rails.cache.delete_matched("sticker_error*")
    Rails.logger.info("[STICKER_MONITORING] Error statistics reset")
  end
end