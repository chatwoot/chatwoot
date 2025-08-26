class CustomFeaturesLogger
  include Singleton

  def initialize
    @logger_prefix = '[CustomFeatures]'
  end

  # Info level logging for normal operations
  def info(message, account_id: nil, feature_name: nil, **metadata)
    log_with_context(:info, message, account_id: account_id, feature_name: feature_name, **metadata)
  end

  # Warning level logging for potential issues
  def warn(message, account_id: nil, feature_name: nil, **metadata)
    log_with_context(:warn, message, account_id: account_id, feature_name: feature_name, **metadata)
  end

  # Error level logging for actual problems
  def error(message, account_id: nil, feature_name: nil, error: nil, **metadata)
    log_with_context(:error, message, account_id: account_id, feature_name: feature_name, error: error, **metadata)
  end

  # Debug level logging for development/troubleshooting
  def debug(message, account_id: nil, feature_name: nil, **metadata)
    log_with_context(:debug, message, account_id: account_id, feature_name: feature_name, **metadata)
  end

  # Log configuration changes
  def config_change(action, details = {})
    info("Configuration #{action}",
         operation: action,
         details: details,
         timestamp: Time.current.iso8601)
  end

  # Log feature usage/access
  def feature_access(account_id, feature_name, action = 'accessed')
    info("Feature #{action}",
         account_id: account_id,
         feature_name: feature_name,
         action: action,
         timestamp: Time.current.iso8601)
  end

  private

  def log_with_context(level, message, account_id: nil, feature_name: nil, error: nil, **metadata)
    context_parts = []
    context_parts << "Account:#{account_id}" if account_id
    context_parts << "Feature:#{feature_name}" if feature_name

    formatted_message = "#{@logger_prefix} #{message}"
    formatted_message += " [#{context_parts.join(', ')}]" if context_parts.any?

    log_data = {
      message: formatted_message,
      level: level,
      timestamp: Time.current.iso8601,
      component: 'custom_features'
    }

    log_data[:account_id] = account_id if account_id
    log_data[:feature_name] = feature_name if feature_name
    log_data[:error_message] = error.message if error
    log_data[:error_class] = error.class.name if error
    log_data[:error_backtrace] = error.backtrace&.first(5) if error && Rails.env.development?
    log_data.merge!(metadata) if metadata.any?

    # Use structured logging when available
    if Rails.logger.respond_to?(:info) && level == :info
      Rails.logger.info(log_data)
    else
      Rails.logger.send(level, formatted_message)
    end

    # In development, also output to console for visibility
    return unless Rails.env.development?

    puts "#{level.upcase}: #{formatted_message}"
    puts "  Metadata: #{metadata.inspect}" if metadata.any?
  end
end