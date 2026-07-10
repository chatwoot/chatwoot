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

    # Rails would allow requests to paths with extensions, so lets compare against the path with extension stripped
    # example /auth & /auth.json would both work
    def path_without_extensions
      path[/^[^.]+/]
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

  throttle('public_tracked_links/ip', limit: 60, period: 1.minute) do |req|
    req.ip if req.get? && req.path_without_extensions.start_with?('/l/')
  end

  throttle('public_google_conversions/ip', limit: 60, period: 1.minute) do |req|
    req.ip if req.get? && req.path.start_with?('/google_conversions/')
  end

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
  # Exclude MFA verification attempts from regular login throttling
  throttle('login/ip', limit: 5, period: 5.minutes) do |req|
    if req.path_without_extensions == '/auth/sign_in' && req.post? && req.params['mfa_token'].blank?
      # Skip if this is an MFA verification request
      req.ip
    end
  end

  throttle('login/email', limit: 10, period: 15.minutes) do |req|
    # Skip if this is an MFA verification request
    if req.path_without_extensions == '/auth/sign_in' && req.post? && req.params['mfa_token'].blank?
      # ref: https://github.com/rack/rack-attack/issues/399
      # NOTE: This line used to throw ArgumentError /rails/action_mailbox/sendgrid/inbound_emails : invalid byte sequence in UTF-8
      # Hence placed in the if block
      email = req.params['email'].presence || ActionDispatch::Request.new(req.env).params['email'].presence
      email.to_s.downcase.gsub(/\s+/, '')
    end
  end

  ## Reset password throttling
  throttle('reset_password/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extensions == '/auth/password' && req.post?
  end

  throttle('reset_password/email', limit: 5, period: 1.hour) do |req|
    if req.path_without_extensions == '/auth/password' && req.post?
      email = req.params['email'].presence || ActionDispatch::Request.new(req.env).params['email'].presence
      email.to_s.downcase.gsub(/\s+/, '')
    end
  end

  ## Resend confirmation throttling (unauthenticated)
  throttle('resend_confirmation/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extensions == '/resend_confirmation' && req.post?
  end

  throttle('resend_confirmation/email', limit: 5, period: 1.hour) do |req|
    if req.path_without_extensions == '/resend_confirmation' && req.post?
      email = req.params['email'].presence || ActionDispatch::Request.new(req.env).params['email'].presence
      email.to_s.downcase.gsub(/\s+/, '')
    end
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
    req.ip if req.path_without_extensions == '/auth/sign_in' && req.post? && req.params['mfa_token'].present?
  end

  throttle('mfa_login/token', limit: 10, period: 1.minute) do |req|
    if req.path_without_extensions == '/auth/sign_in' && req.post?
      # Track by MFA token to prevent brute force on a specific token
      mfa_token = req.params['mfa_token'].presence
      (mfa_token.presence)
    end
  end

  ## Prevent Brute-Force Signup Attacks ###
  throttle('accounts/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extensions == '/api/v1/accounts' && req.post?
  end

  ##-----------------------------------------------##

  ###-----------------------------------------------###
  ###-----------Widget API Throttling---------------###
  ###-----------------------------------------------###

  # Rack attack on widget APIs can be disabled by setting ENABLE_RACK_ATTACK_WIDGET_API to false
  # For clients using the widgets in specific conditions like inside and iframe
  # TODO: Deprecate this feature in future after finding a better solution
  if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK_WIDGET_API', true))
    ## Prevent Conversation Bombing on Widget APIs ###
    throttle('api/v1/widget/conversations', limit: 6, period: 12.hours) do |req|
      req.ip if req.path_without_extensions == '/api/v1/widget/conversations' && req.post?
    end

    ## Prevent Contact update Bombing in Widget API ###
    throttle('api/v1/widget/contacts', limit: 60, period: 1.hour) do |req|
      req.ip if req.path_without_extensions == '/api/v1/widget/contacts' && (req.patch? || req.put?)
    end

    ## Prevent Conversation Bombing through multiple sessions
    throttle('widget?website_token={website_token}&cw_conversation={x-auth-token}', limit: 5, period: 1.hour) do |req|
      req.ip if req.path_without_extensions == '/widget' && ActionDispatch::Request.new(req.env).params['cw_conversation'].blank?
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

  # Throttle by individual user (based on uid)
  throttle('/api/v2/accounts/:account_id/reports/user', limit: ENV.fetch('RATE_LIMIT_REPORTS_API_USER_LEVEL', '100').to_i, period: 1.minute) do |req|
    match_data = %r{/api/v2/accounts/(?<account_id>\d+)/reports}.match(req.path)
    # Extract user identification (uid for web, api_access_token for API requests)
    user_uid = req.get_header('HTTP_UID')
    api_access_token = req.get_header('HTTP_API_ACCESS_TOKEN') || req.get_header('api_access_token')

    # Use uid if present, otherwise fallback to api_access_token for tracking
    user_identifier = user_uid.presence || api_access_token.presence

    "#{user_identifier}:#{match_data[:account_id]}" if match_data.present? && user_identifier.present?
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

    user_uid = req.get_header('HTTP_UID')
    api_access_token = req.get_header('HTTP_API_ACCESS_TOKEN') || req.get_header('api_access_token')
    user_identifier = user_uid.presence || api_access_token.presence

    "#{user_identifier}:#{match_data[:account_id]}" if user_identifier.present?
  end

  ###-----------------------------------------------###
  ###-----------CRM Integration Token Throttle------###
  ###-----------------------------------------------###

  # Per-token rate limit for the CRM inbound API (plan §3.3, B-API2). Keyed on
  # the api_access_token header so a single integration token (n8n) can't hammer
  # the CRM endpoints. Every CRM endpoint (cards/pipelines/stages and the CRM
  # reports) is nested under /api/v1/accounts/:id/crm/, so this single prefix
  # covers the full token-reachable surface.
  CRM_TOKEN_THROTTLE_PATH = %r{\A/api/v1/accounts/\d+/crm/}.freeze

  throttle('crm/integration_token', limit: ENV.fetch('RATE_LIMIT_CRM_INTEGRATION_TOKEN', '300').to_i, period: 1.minute) do |req|
    if CRM_TOKEN_THROTTLE_PATH.match?(req.path)
      api_access_token = req.get_header('HTTP_API_ACCESS_TOKEN') || req.get_header('api_access_token')
      api_access_token.presence
    end
  end

  ###-----------------------------------------------###
  ###-----------Public Booking (CRM S6)-------------###
  ###-----------------------------------------------###

  # Public, unauthenticated booking surface (/public/api/v1/booking/:slug). Both
  # endpoints are prime abuse targets, so throttle per IP. The slug segment is
  # opaque, so we path-match the prefix + verb instead of an exact path.
  PUBLIC_BOOKING_PATH = %r{\A/public/api/v1/booking/}.freeze
  PUBLIC_BOOKING_SLOTS_PATH = %r{\A/public/api/v1/booking/[^/]+/slots\z}.freeze
  PUBLIC_BOOKING_CONFIRM_PATH = %r{\A/public/api/v1/booking/(?<slug>[^/]+)/confirm\z}.freeze
  # The bare slug create endpoint (POST .../booking/:slug, NOT /slots or /confirm).
  PUBLIC_BOOKING_CREATE_PATH = %r{\A/public/api/v1/booking/(?<slug>[^/]+)\z}.freeze

  # Booking attempts (POST to the slug) now trigger a REAL email, so they are the
  # most abusable surface. Tighten to ~10 PER HOUR per IP (was per-minute).
  throttle('public_booking/create_ip', limit: ENV.fetch('RATE_LIMIT_PUBLIC_BOOKING', '10').to_i, period: 1.hour) do |req|
    req.ip if req.post? && PUBLIC_BOOKING_CREATE_PATH.match?(req.path_without_extensions)
  end

  # NOTE: these throttles are PER IP only — we deliberately do NOT add per-slug
  # caps. Rack::Attack counts BEFORE any validation, so a per-slug quota could be
  # drained by anyone who knows the (public) slug using invalid payloads/tokens — an
  # attacker-triggerable denial of service that would lock legitimate bookers out of
  # a specific page. Per-IP limits bound each abuse source (the standard defense for
  # "email me a link" endpoints); distributed abuse is an upstream-infra concern.

  # Confirm endpoint (POST .../confirm) per IP (~20/hour): deters brute-forcing the
  # signed token (HMAC-signed + 30-min expiry, so already infeasible).
  throttle('public_booking/confirm_ip', limit: ENV.fetch('RATE_LIMIT_PUBLIC_BOOKING_CONFIRM', '20').to_i, period: 1.hour) do |req|
    req.ip if req.post? && PUBLIC_BOOKING_CONFIRM_PATH.match?(req.path_without_extensions)
  end

  # Slot lookups (GET .../slots) — cheaper but still rate-limited to deter scraping.
  throttle('public_booking/slots_ip', limit: ENV.fetch('RATE_LIMIT_PUBLIC_BOOKING_SLOTS', '60').to_i, period: 1.minute) do |req|
    req.ip if req.get? && PUBLIC_BOOKING_SLOTS_PATH.match?(req.path_without_extensions)
  end

  # CRM calendar push webhooks (S7-B): public + unauthenticated. Generous per-IP cap
  # (providers batch from their own ranges) just to bound abuse — the handler only
  # verifies a secret and enqueues, never trusts the payload.
  CRM_CALENDAR_WEBHOOK_PATH = %r{\A/webhooks/crm_calendar/}.freeze
  throttle('crm_calendar_webhook/ip', limit: ENV.fetch('RATE_LIMIT_CRM_CALENDAR_WEBHOOK', '300').to_i, period: 1.minute) do |req|
    req.ip if req.post? && CRM_CALENDAR_WEBHOOK_PATH.match?(req.path_without_extensions)
  end

  ## ----------------------------------------------- ##
end

# Throttled responder: emit a stable JSON envelope and an explicit Retry-After
# (seconds) computed from the throttle period. Applies to every throttle.
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data'] || {}
  now = match_data[:epoch_time] || Time.now.to_i
  period = match_data[:period].to_i
  retry_after = period.positive? ? (period - (now % period)) : period

  headers = {
    'Content-Type' => 'application/json',
    'Retry-After' => retry_after.to_s
  }
  body = { error: { code: 'rate_limited', message: 'Too many requests. Retry later.' } }.to_json
  [429, headers, [body]]
end

# Log blocked events
ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  req = payload[:request]

  user_uid = req.get_header('HTTP_UID')
  api_access_token = req.get_header('HTTP_API_ACCESS_TOKEN') || req.get_header('api_access_token')

  # Mask the token if present
  masked_api_token = api_access_token.present? ? "#{api_access_token[0..4]}...[REDACTED]" : nil

  # Use uid if present, otherwise fallback to masked api_access_token for tracking
  user_identifier = user_uid.presence || masked_api_token.presence || 'unknown_user'

  # Extract account ID if present
  account_match = %r{/accounts/(?<account_id>\d+)}.match(req.path)
  account_id = account_match ? account_match[:account_id] : 'unknown_account'

  Rails.logger.warn(
    "[Rack::Attack][Blocked] remote_ip: \"#{req.remote_ip}\", " \
    "path: \"#{req.path}\", " \
    "user_identifier: \"#{user_identifier}\", " \
    "account_id: \"#{account_id}\", " \
    "method: \"#{req.request_method}\", " \
    "user_agent: \"#{req.user_agent}\""
  )
end

Rack::Attack.enabled = Rails.env.production? ? ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK', true)) : false
