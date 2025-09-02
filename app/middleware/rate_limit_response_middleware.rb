class RateLimitResponseMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Handle Rack::Attack throttled responses
    if status == 429 && headers['X-RateLimit-Limit']
      request = Rack::Request.new(env)
      
      # Extract account context for personalised messaging
      account_id = extract_account_id_from_path(request.path)
      limits_info = get_rate_limit_context(account_id) if account_id

      # Create friendly JSON response
      json_response = {
        error: 'Rate limit exceeded',
        message: friendly_rate_limit_message(limits_info, request),
        code: 'RATE_LIMIT_EXCEEDED',
        retry_after: 60,
        limits: {
          current: headers['X-RateLimit-Limit']&.to_i,
          remaining: headers['X-RateLimit-Remaining']&.to_i,
          reset_at: Time.at(headers['X-RateLimit-Reset']&.to_i)
        },
        account_limits: limits_info&.dig(:current_limits) || {},
        upgrade_available: limits_info&.dig(:upgrade_available) || false
      }

      # Log the rate limit hit with context
      log_rate_limit_hit(request, account_id, limits_info)

      headers['Content-Type'] = 'application/json'
      response_body = JSON.generate(json_response)
      
      [429, headers, [response_body]]
    else
      [status, headers, response]
    end
  end

  private

  def extract_account_id_from_path(path)
    return nil unless path
    
    if (match = %r{^/api/v[12]/accounts/(?<account_id>\d+)}.match(path))
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
    Rails.logger.error("Failed to get rate limit context: #{e.message}")
    nil
  end

  def friendly_rate_limit_message(limits_info, request)
    plan = limits_info&.dig(:plan) || 'basic'
    
    base_message = case plan
    when 'basic'
      'You have reached your Basic plan rate limit. Consider upgrading to Pro for higher limits.'
    when 'pro' 
      'You have reached your Pro plan rate limit. Consider upgrading to Premium for higher limits.'
    when 'premium'
      'You have reached your Premium plan rate limit.'
    when 'app'
      'You have reached your App integration rate limit.'
    when 'custom'
      'You have reached your custom rate limit. Please contact support if you need higher limits.'
    else
      'You have exceeded the rate limit.'
    end

    # Add module-specific guidance
    module_guidance = case request.path
    when %r{/conversations|/messages}
      ' This limit helps ensure reliable messaging performance.'
    when %r{/reports}
      ' Reports are rate-limited to maintain system performance.'
    when %r{/webhooks/whatsapp}
      ' WhatsApp webhook processing is limited to prevent overwhelming the system.'
    when %r{/widget}
      ' Widget API calls are limited to ensure responsive chat experiences.'
    else
      ''
    end

    "#{base_message}#{module_guidance} Please wait a minute before trying again."
  end

  def log_rate_limit_hit(request, account_id, limits_info)
    Rails.logger.warn(
      "[Rate Limit Hit] " \
      "account_id: #{account_id || 'unknown'}, " \
      "path: #{request.path}, " \
      "method: #{request.request_method}, " \
      "plan: #{limits_info&.dig(:plan) || 'unknown'}, " \
      "ip: #{request.ip}, " \
      "user_agent: #{request.user_agent}"
    )
  end
end