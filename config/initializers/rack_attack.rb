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
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(redis: $velma)

  class Request < ::Rack::Request
    # You many need to specify a method to fetch the correct remote IP address
    # if the web server is behind a load balancer.
    def remote_ip
      @remote_ip ||= (env['action_dispatch.remote_ip'] || ip).to_s
    end

    def allowed_ip?
      allowed_ips = ['127.0.0.1', '::1']
      allowed_ips.include?(remote_ip)
    end

    # Rails would allow requests to paths with extentions, so lets compare against the path with extention stripped
    # example /auth & /auth.json would both work
    def path_without_extentions
      path[/^[^.]+/]
    end
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

  throttle('req/ip', limit: 300, period: 1.minute, &:ip)

  ### Prevent Brute-Force Super Admin Login Attacks ###
  throttle('super_admin_login/ip', limit: 5, period: 5.minutes) do |req|
    req.ip if req.path_without_extentions == '/super_admin/sign_in' && req.post?
  end

  throttle('super_admin_login/email', limit: 5, period: 15.minutes) do |req|
    if req.path_without_extentions == '/super_admin/sign_in' && req.post?
      # NOTE: This line used to throw ArgumentError /rails/action_mailbox/sendgrid/inbound_emails : invalid byte sequence in UTF-8
      # Hence placed in the if block
      # ref: https://github.com/rack/rack-attack/issues/399
      email = req.params['email'].presence || ActionDispatch::Request.new(req.env).params['email'].presence
      email.to_s.downcase.gsub(/\s+/, '')
    end
  end

  # ### Prevent Brute-Force Login Attacks ###
  throttle('login/ip', limit: 5, period: 5.minutes) do |req|
    req.ip if req.path_without_extentions == '/auth/sign_in' && req.post?
  end

  throttle('login/email', limit: 10, period: 15.minutes) do |req|
    if req.path_without_extentions == '/auth/sign_in' && req.post?
      # ref: https://github.com/rack/rack-attack/issues/399
      # NOTE: This line used to throw ArgumentError /rails/action_mailbox/sendgrid/inbound_emails : invalid byte sequence in UTF-8
      # Hence placed in the if block
      email = req.params['email'].presence || ActionDispatch::Request.new(req.env).params['email'].presence
      email.to_s.downcase.gsub(/\s+/, '')
    end
  end

  ## Reset password throttling
  throttle('reset_password/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extentions == '/auth/password' && req.post?
  end

  throttle('reset_password/email', limit: 5, period: 1.hour) do |req|
    if req.path_without_extentions == '/auth/password' && req.post?
      email = req.params['email'].presence || ActionDispatch::Request.new(req.env).params['email'].presence
      email.to_s.downcase.gsub(/\s+/, '')
    end
  end

  ## Prevent Brute-Force Signup Attacks ###
  throttle('accounts/ip', limit: 5, period: 30.minutes) do |req|
    req.ip if req.path_without_extentions == '/api/v1/accounts' && req.post?
  end

  ## Prevent Conversation Bombing on Widget APIs ###
  throttle('api/v1/widget/conversations', limit: 6, period: 12.hours) do |req|
    req.ip if req.path_without_extentions == '/api/v1/widget/conversations' && req.post?
  end

  ## Prevent Contact update Bombing in Widget API ###
  throttle('api/v1/widget/contacts', limit: 60, period: 1.hour) do |req|
    req.ip if req.path_without_extentions == '/api/v1/widget/contacts' && (req.patch? || req.put?)
  end

  ## Prevent Conversation Bombing through multiple sessions
  throttle('widget?website_token={website_token}&cw_conversation={x-auth-token}', limit: 5, period: 1.hour) do |req|
    req.ip if req.path_without_extentions == '/widget' && ActionDispatch::Request.new(req.env).params['cw_conversation'].blank?
  end
end

# Log blocked events
ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  Rails.logger.warn "[Rack::Attack][Blocked] remote_ip: \"#{payload[:request].remote_ip}\", path: \"#{payload[:request].path}\""
end

Rack::Attack.enabled = Rails.env.production? ? ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_RACK_ATTACK', true)) : false
