module RequestExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from Rack::Attack::Throttle, with: :render_throttled_error if defined?(Rack::Attack)
  end

  private

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    log_handled_error(e)
    render_not_found_error('Resource could not be found')
  rescue Pundit::NotAuthorizedError => e
    log_handled_error(e)
    render_unauthorized('You are not authorized to do this action')
  rescue ActionController::ParameterMissing => e
    log_handled_error(e)
    render_could_not_create_error(e.message)
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.reset
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found_error(message)
    render json: { error: message }, status: :not_found
  end

  def render_could_not_create_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_payment_required(message)
    render json: { error: message }, status: :payment_required
  end

  def render_internal_server_error(message)
    render json: { error: message }, status: :internal_server_error
  end

  def render_record_invalid(exception)
    log_handled_error(exception)
    render json: {
      message: exception.record.errors.full_messages.join(', '),
      attributes: exception.record.errors.attribute_names
    }, status: :unprocessable_entity
  end

  def render_error_response(exception)
    log_handled_error(exception)
    render json: exception.to_hash, status: exception.http_status
  end

  def render_throttled_error(exception = nil)
    log_handled_error(exception) if exception
    
    # Extract account context for personalised messaging
    account_id = extract_account_id_from_request
    limits_info = get_rate_limit_context(account_id) if account_id

    render json: {
      error: 'Rate limit exceeded',
      message: friendly_rate_limit_message(limits_info),
      code: 'RATE_LIMIT_EXCEEDED',
      retry_after: 60,
      account_limits: limits_info&.dig(:current_limits) || {},
      upgrade_available: limits_info&.dig(:upgrade_available) || false
    }, status: :too_many_requests
  end

  def log_handled_error(exception)
    logger.info("Handled error: #{exception.inspect}")
  end

  private

  def extract_account_id_from_request
    return nil unless request.path
    
    if (match = %r{^/api/v[12]/accounts/(?<account_id>\d+)}.match(request.path))
      match[:account_id].to_i
    end
  end

  def get_rate_limit_context(account_id)
    limits = Weave::Core::RateLimits.current_limits_for_account(account_id)
    plan = limits.values.first&.dig(:plan) || 'basic'
    
    {
      current_limits: limits.transform_values { |v| v[:current_limit] },
      plan: plan,
      upgrade_available: %w[basic pro].include?(plan)
    }
  rescue StandardError => e
    logger.error("Failed to get rate limit context: #{e.message}")
    nil
  end

  def friendly_rate_limit_message(limits_info)
    return 'You have exceeded the rate limit. Please wait a moment and try again.' unless limits_info

    plan = limits_info[:plan]
    case plan
    when 'basic'
      'You have reached your Basic plan rate limit. Consider upgrading to Pro for higher limits, or wait a minute before trying again.'
    when 'pro' 
      'You have reached your Pro plan rate limit. Consider upgrading to Premium for higher limits, or wait a minute before trying again.'
    when 'premium'
      'You have reached your Premium plan rate limit. Please wait a minute before trying again.'
    when 'app'
      'You have reached your App integration rate limit. Please wait a minute before trying again.'
    when 'custom'
      'You have reached your custom rate limit. Please contact support if you need higher limits, or wait a minute before trying again.'
    else
      'You have exceeded the rate limit. Please wait a moment and try again.'
    end
  end
end
