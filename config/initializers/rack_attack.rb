class Rack::Attack
  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # https://github.com/rack/rack-attack/issues/102
  # Rails 7.1 automatically adds its own ConnectionPool around RedisCacheStore.
  # Because `$velma` is *already* a ConnectionPool, double-wrapping causes
  # Redis calls like `get` to hit the outer wrapper and explode.
  # `pool: false` tells Rails to skip its internal pool and use ours directly.
  # TODO: We can use build in connection pool in future upgrade
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(redis: $velma, pool: false)

  class Request < ::Rack::Request
    # You may need to specify a method to fetch the correct remote IP address
    # if the web server is behind a load balancer.
    def remote_ip
      @remote_ip ||= (env['action_dispatch.remote_ip'] || ip).to_s
    end

    def allowed_ip?
      default_allowed_ips = ['127.0.0.1', '::1']
      env_allowed_ips = ENV.fetch('RACK_ATTACK_ALLOWED_IPS', '').split(',').map(&:strip)
      (default_allowed_ips + env_allowed_ips).include?(remote_ip)
    end

    # Rails allows paths with extensions and trailing slashes, so compare against a normalized path.
    # For example, /auth, /auth.json, and /auth/ should all use the same throttle.
    def path_without_extensions
      normalized_path = path[/^[^.]+/]
      normalized_path == '/' ? normalized_path : normalized_path.sub(%r{/+\z}, '')
    end

    # Rack's params skip JSON bodies, so fall back to ActionDispatch to read them
    # (the SPA and mobile clients post JSON). nil for blank/non-string values so a
    # throttle keyed on this skips rather than sharing one empty-string bucket, and
    # fails open on unparseable input (the per-ip throttle still applies).
    def auth_param(key)
      value = params[key].presence || ActionDispatch::Request.new(env).params[key].presence
      value if value.is_a?(String)
    rescue StandardError
      nil
    end

    # Keep API tokens in the same bucket regardless of which header carries them.
    def api_user_identifier(mask_token: false)
      scheme, token = ActionDispatch::Request.new(env).authorization.to_s.split(' ', 2)
      if scheme&.casecmp?('Bearer')
        identifier = bearer_user_identifier(token)
        return mask_api_token(identifier) if mask_token && identifier == token

        return identifier
      end

      legacy_user_identifier(mask_token: mask_token)
    end

    def mask_api_token(token)
      "#{token[0..4]}...[REDACTED]" if token.present?
    end

    def legacy_user_identifier(mask_token:)
      user_uid = get_header('HTTP_UID').presence
      return user_uid if user_uid

      token = get_header('HTTP_API_ACCESS_TOKEN').presence || get_header('api_access_token').presence
      mask_token ? mask_api_token(token) : token
    end

    def bearer_user_identifier(token)
      credentials = JSON.parse(Base64.strict_decode64(token.to_s.split.last.to_s))
      # Dashboard Bearer credentials must retain the existing UID-based bucket.
      if credentials.is_a?(Hash) && credentials.values_at('uid', 'client', 'access-token').all?(&:present?)
        get_header('HTTP_UID').presence || credentials['uid']
      else
        token.presence
      end
    rescue ArgumentError, JSON::ParserError
      token.presence
    end

    # include_header only for sign-in, which merges the 'email' header into params;
    # reset/resend read params only, so honoring it there lets a spoofed header
    # exhaust a victim's bucket.
    def normalized_auth_email(include_header: false)
      email = auth_param('email')
      email = get_header('HTTP_EMAIL').presence if email.nil? && include_header
      email&.downcase&.gsub(/\s+/, '')
    end
  end

  ### Safelist IPs from Environment Variable ###
  #
  # This block ensures requests from any IP present in RACK_ATTACK_ALLOWED_IPS
  # will bypass Rack::Attack’s throttling rules.
  #
  # Example: RACK_ATTACK_ALLOWED_IPS="127.0.0.1,::1,192.168.0.10"

  Rack::Attack.safelist('trusted IPs', &:allowed_ip?)

  # Safelist health check endpoint so it never touches Redis for throttle tracking.
  # This keeps /health fully dependency-free for ALB liveness checks.
  Rack::Attack.safelist('health check') do |req|
    req.path == '/health'
  end

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"

  throttle('req/ip', limit: ENV.fetch('RACK_ATTACK_LIMIT', '3000').to_i, period: 1.minute, &:ip)

  ###-----------------------------------------------###
  ###-----Authentication Related Throttling---------###
  ###-----------------------------------------------###

  ### Prevent Brute-Force Super Admin Login Attacks ###
  throttle('super_admin_login/ip', limit: 5, period: 5.minutes) do |req|
    req.ip if req.path_without_extensions == '/super_admin/sign_in' && req.post?
  end

  throttle('super_admin_login/email', limit: 5, period: 15.minutes) do |req|
    if req.path_without_extensions == '/super_admin/sign_in' && req.post?
      # NOTE: This line used to throw ArgumentError /rails/action_mailbox/sendgrid/inbound_emails : invalid byte sequence in UTF-8
      # Hence placed in the if block
      # ref: https://github.com/rack/rack-attack/issues/399
      email = req.params['email'].presence || ActionDispatch::Request.new(req.env).params['email'].presence
      email.to_s.downcase.gsub(/\s+/, '')
    end
  end

  # ### Prevent Brute-Force Login Attacks ###
  # Exclude MFA verification and enforced MFA setup attempts from regular login throttling
  throttle('login/ip', limit: 5, period: 5.minutes) do |req|
    if req.path_without_extensions == '/auth/sign_in' && req.post? && req.auth_param('mfa_token').blank? &&
       req.auth_param('mfa_setup_token').blank?
      req.ip
    end
  end

  throttle('login/email', limit: 10, period: 15.minutes) do |req|
    if req.path_without_extensions == '/auth/sign_in' && req.post? && req.auth_param('mfa_token').blank? &&
       req.auth_param('mfa_setup_token').blank?
      req.normalized_auth_email(include_header: true)
    end
  end

  ## Reset password throttling
  throttle('reset_password/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extensions == '/auth/password' && req.post?
  end

  throttle('reset_password/email', limit: 5, period: 1.hour) do |req|
    req.normalized_auth_email if req.path_without_extensions == '/auth/password' && req.post?
  end

  ## Resend confirmation throttling (unauthenticated)
  throttle('resend_confirmation/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extensions == '/resend_confirmation' && req.post?
  end

  throttle('resend_confirmation/email', limit: 5, period: 1.hour) do |req|
    req.normalized_auth_email if req.path_without_extensions == '/resend_confirmation' && req.post?
  end

  ## Resend confirmation throttling (authenticated)
  throttle('resend_confirmation_auth/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extensions == '/api/v1/profile/resend_confirmation' && req.post?
  end

  ## MFA throttling - prevent brute force attacks
  throttle('mfa_verification/ip', limit: 5, period: 1.minute) do |req|
    if req.path_without_extensions == '/api/v1/profile/mfa'
      req.ip if req.delete? # Throttle disable attempts
    elsif req.path_without_extensions.match?(%r{/api/v1/profile/mfa/(verify|backup_codes)})
      req.ip if req.post? # Throttle verify and backup_codes attempts
    end
  end

  # Separate rate limiting for MFA verification attempts
  throttle('mfa_login/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path_without_extensions == '/auth/sign_in' && req.post? && req.auth_param('mfa_token').present?
  end

  throttle('mfa_login/token', limit: 10, period: 1.minute) do |req|
    # Track by MFA token to prevent brute force on a specific token
    req.auth_param('mfa_token') if req.path_without_extensions == '/auth/sign_in' && req.post?
  end

  # Separate rate limiting for enforced MFA setup verification attempts
  throttle('mfa_setup_login/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path_without_extensions == '/auth/sign_in' && req.post? && req.auth_param('mfa_setup_token').present?
  end

  throttle('mfa_setup_login/token', limit: 10, period: 1.minute) do |req|
    # Track by setup token to prevent brute force on a specific token
    req.auth_param('mfa_setup_token') if req.path_without_extensions == '/auth/sign_in' && req.post?
  end

  ## Prevent Brute-Force Signup Attacks ###
  throttle('accounts/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extensions == '/api/v1/accounts' && req.post?
  end

  ##-----------------------------------------------##

  ###-----------------------------------------------###
  ###-----------Widget API Throttling---------------###
  ###-----------------------------------------------###

  # Set ENABLE_RACK_ATTACK_WIDGET_API to false to disable all widget throttles (e.g. iframe embeds).
  # Each throttle also has its own ENABLE_*/RATE_LIMIT_* override.
  # TODO: Deprecate the blanket ENABLE_RACK_ATTACK_WIDGET_API switch after finding a better solution
  if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK_WIDGET_API', true))
    ## Conversation creation, keyed on (IP, website_token) so widgets behind a shared NAT get separate buckets.
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK_WIDGET_CONVERSATIONS', true))
      throttle('api/v1/widget/conversations',
               limit: ENV.fetch('RATE_LIMIT_WIDGET_CONVERSATIONS', '30').to_i,
               period: 1.minute) do |req|
        next unless req.path_without_extensions == '/api/v1/widget/conversations' && req.post?

        # ActionDispatch precedence (query wins) matches the controller, so a body token can't fork the bucket.
        token = ActionDispatch::Request.new(req.env).params['website_token'].presence
        "#{req.ip}:#{token}" if token
      end
    end

    ## Message creation, keyed the same way, to cap single-conversation floods.
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK_WIDGET_MESSAGES', true))
      throttle('api/v1/widget/messages',
               limit: ENV.fetch('RATE_LIMIT_WIDGET_MESSAGES', '60').to_i,
               period: 1.minute) do |req|
        next unless req.path_without_extensions == '/api/v1/widget/messages' && req.post?

        token = ActionDispatch::Request.new(req.env).params['website_token'].presence
        "#{req.ip}:#{token}" if token
      end
    end

    ## Prevent Contact update Bombing in Widget API ###
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK_WIDGET_CONTACTS', true))
      throttle('api/v1/widget/contact',
               limit: ENV.fetch('RATE_LIMIT_WIDGET_CONTACTS', '60').to_i,
               period: 1.hour) do |req|
        req.ip if req.path_without_extensions == '/api/v1/widget/contact' && (req.patch? || req.put?)
      end
    end

    ## Prevent Conversation Bombing through repeated widget loads
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK_WIDGET_LOAD', true))
      throttle('widget?website_token={website_token}&cw_conversation={x-auth-token}',
               limit: ENV.fetch('RATE_LIMIT_WIDGET_LOAD', '200').to_i,
               period: 1.hour) do |req|
        req.ip if req.path_without_extensions == '/widget' && ActionDispatch::Request.new(req.env).params['cw_conversation'].blank?
      end
    end

    ## Prevent Transcript Bombing on Widget API ###
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK_WIDGET_TRANSCRIPT', true))
      throttle('api/v1/widget/conversations/transcript',
               limit: ENV.fetch('RATE_LIMIT_WIDGET_TRANSCRIPT', '5').to_i,
               period: 1.hour) do |req|
        req.ip if req.path_without_extensions == '/api/v1/widget/conversations/transcript' && req.post?
      end
    end
  end

  ##-----------------------------------------------##

  ###-----------------------------------------------###
  ###----------Application API Throttling-----------###
  ###-----------------------------------------------###

  ## Prevent Abuse of Converstion Transcript APIs ###
  throttle('/api/v1/accounts/:account_id/conversations/:conversation_id/transcript',
           limit: ENV.fetch('RATE_LIMIT_CONVERSATION_TRANSCRIPT', '1000').to_i, period: 1.hour) do |req|
    match_data = %r{/api/v1/accounts/(?<account_id>\d+)/conversations/(?<conversation_id>\d+)/transcript}.match(req.path)
    match_data[:account_id] if match_data.present?
  end

  ## Prevent abuse of conversation delete API (per account)
  throttle('/api/v1/accounts/:account_id/conversations/:id DELETE',
           limit: ENV.fetch('RATE_LIMIT_CONVERSATION_DELETE', '60').to_i, period: 1.minute) do |req|
    next unless req.delete?

    match_data = %r{\A/api/v1/accounts/(?<account_id>\d+)/conversations/(?<id>\d+)/?\z}.match(req.path_without_extensions)
    match_data[:account_id] if match_data.present?
  end

  ## Prevent abuse of agent create APIs (per account, covers bulk_create)
  throttle('/api/v1/accounts/:account_id/agents POST',
           limit: ENV.fetch('RATE_LIMIT_AGENT_CREATE', '100').to_i, period: 1.day) do |req|
    next unless req.post?

    match_data = %r{\A/api/v1/accounts/(?<account_id>\d+)/agents(?:/bulk_create)?/?\z}.match(req.path_without_extensions)
    match_data[:account_id] if match_data.present?
  end

  ## Prevent abuse of agent delete API (per account)
  throttle('/api/v1/accounts/:account_id/agents/:id DELETE',
           limit: ENV.fetch('RATE_LIMIT_AGENT_DELETE', '50').to_i, period: 1.day) do |req|
    next unless req.delete?

    match_data = %r{\A/api/v1/accounts/(?<account_id>\d+)/agents/(?<id>\d+)/?\z}.match(req.path_without_extensions)
    match_data[:account_id] if match_data.present?
  end

  ## Prevent Abuse of attachment upload APIs ##
  throttle('/api/v1/accounts/:account_id/upload', limit: 60, period: 1.hour) do |req|
    match_data = %r{/api/v1/accounts/(?<account_id>\d+)/upload}.match(req.path)
    match_data[:account_id] if match_data.present?
  end

  ## Prevent abuse of contact search api
  throttle('/api/v1/accounts/:account_id/contacts/search', limit: ENV.fetch('RATE_LIMIT_CONTACT_SEARCH', '100').to_i, period: 1.minute) do |req|
    match_data = %r{/api/v1/accounts/(?<account_id>\d+)/contacts/search}.match(req.path)
    match_data[:account_id] if match_data.present?
  end

  reports_api_user_level_limit = ENV.fetch('RATE_LIMIT_REPORTS_API_USER_LEVEL', '100').to_i
  reports_drilldown_api_user_level_limit = ENV.fetch(
    'RATE_LIMIT_REPORTS_DRILLDOWN_API_USER_LEVEL',
    [(reports_api_user_level_limit / 10), 1].max
  ).to_i

  # Throttle drilldown requests by dashboard UID or API token
  throttle('/api/v2/accounts/:account_id/reports/drilldown/user',
           limit: reports_drilldown_api_user_level_limit, period: 1.minute) do |req|
    match_data = %r{\A/api/v2/accounts/(?<account_id>\d+)/reports/drilldown\z}.match(req.path_without_extensions)
    next unless match_data.present? && req.get?

    user_identifier = req.api_user_identifier

    "#{user_identifier}:#{match_data[:account_id]}" if user_identifier.present?
  end

  # Throttle by dashboard UID or API token
  throttle('/api/v2/accounts/:account_id/reports/user', limit: reports_api_user_level_limit, period: 1.minute) do |req|
    match_data = %r{/api/v2/accounts/(?<account_id>\d+)/reports}.match(req.path)
    next if match_data.blank?

    user_identifier = req.api_user_identifier

    "#{user_identifier}:#{match_data[:account_id]}" if user_identifier.present?
  end

  ## Prevent abuse of reports api at account level
  throttle('/api/v2/accounts/:account_id/reports', limit: ENV.fetch('RATE_LIMIT_REPORTS_API_ACCOUNT_LEVEL', '1000').to_i, period: 1.minute) do |req|
    match_data = %r{/api/v2/accounts/(?<account_id>\d+)/reports}.match(req.path)
    match_data[:account_id] if match_data.present?
  end

  ## Prevent increased use of conversations meta API per user
  throttle('/api/v1/accounts/:account_id/conversations/meta/user',
           limit: ENV.fetch('RATE_LIMIT_CONVERSATIONS_META', '30').to_i, period: 1.minute) do |req|
    match_data = %r{/api/v1/accounts/(?<account_id>\d+)/conversations/meta}.match(req.path)
    next unless match_data.present? && req.get?

    user_identifier = req.api_user_identifier

    "#{user_identifier}:#{match_data[:account_id]}" if user_identifier.present?
  end

  ## ----------------------------------------------- ##
end

# Log blocked events
ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  req = payload[:request]

  user_identifier = req.api_user_identifier(mask_token: true) || 'unknown_user'

  # Extract account ID if present
  account_match = %r{/accounts/(?<account_id>\d+)}.match(req.path)
  account_id = account_match ? account_match[:account_id] : 'unknown_account'

  matched_rule = req.env['rack.attack.matched'] || 'unknown_rule'

  Rails.logger.warn(
    "[Rack::Attack][Blocked] remote_ip: \"#{req.remote_ip}\", " \
    "path: \"#{req.path}\", " \
    "matched_rule: \"#{matched_rule}\", " \
    "user_identifier: \"#{user_identifier}\", " \
    "account_id: \"#{account_id}\", " \
    "method: \"#{req.request_method}\", " \
    "user_agent: \"#{req.user_agent}\""
  )
end

Rack::Attack.enabled = Rails.env.production? ? ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK', true)) : false
