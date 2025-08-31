if defined?(Rack::Attack)
  # Per-tenant/module/channel throttles layered over Chatwoot defaults
  Rack::Attack.throttle('wsc:accounts:rpm', limit: ->(req) do
                         account_id = Weave::Core::RateLimits.extract_account_id_from_path(req)
                         next nil unless account_id
                         Weave::Core::RateLimits.limit_for_account_id(account_id, :account_rpm)
                       end, period: 1.minute) do |req|
    account_id = Weave::Core::RateLimits.extract_account_id_from_path(req)
    "acct:#{account_id}" if account_id
  end

  Rack::Attack.throttle('wsc:module:messaging_write', limit: ->(req) do
                         account_id = Weave::Core::RateLimits.extract_account_id_from_path(req)
                         next nil unless account_id
                         Weave::Core::RateLimits.limit_for_account_id(account_id, :messaging_write_rpm)
                       end, period: 1.minute) do |req|
    # Throttle conversation/message writes under account scope
    next unless req.post? || req.patch? || req.put?
    next unless req.path =~ %r{^/api/v1/accounts/\d+/(conversations(\/\d+)?/messages|conversations)$}
    account_id = Weave::Core::RateLimits.extract_account_id_from_path(req)
    "acct:#{account_id}" if account_id
  end

  Rack::Attack.throttle('wsc:channel:whatsapp_inbound', limit: ->(req) do
                         account_id = Weave::Core::RateLimits.extract_account_id_from_whatsapp(req)
                         next nil unless account_id
                         Weave::Core::RateLimits.limit_for_account_id(account_id, :whatsapp_inbound_rpm)
                       end, period: 1.minute) do |req|
    next unless req.post?
    account_id = Weave::Core::RateLimits.extract_account_id_from_whatsapp(req)
    "acct:#{account_id}:whatsapp" if account_id
  end

  Rack::Attack.throttle('wsc:channel:widget_write', limit: ->(req) do
                         account_id = Weave::Core::RateLimits.extract_account_id_from_widget(req)
                         next nil unless account_id
                         Weave::Core::RateLimits.limit_for_account_id(account_id, :widget_write_rpm)
                       end, period: 1.minute) do |req|
    next unless req.post? || req.patch? || req.put?
    next unless req.path.start_with?("/api/v1/widget/messages")
    account_id = Weave::Core::RateLimits.extract_account_id_from_widget(req)
    "acct:#{account_id}:widget" if account_id
  end

  Rack::Attack.throttle('wsc:module:reports', limit: ->(req) do
                         # Only scope dynamic limit; Chatwoot has separate throttles, this is additive & plan-scoped
                         account_id = Weave::Core::RateLimits.extract_account_id_from_path(req)
                         next nil unless account_id
                         Weave::Core::RateLimits.limit_for_account_id(account_id, :reports_rpm)
                       end, period: 1.minute) do |req|
    next unless req.get?
    next unless req.path =~ %r{^/api/v2/accounts/\d+/reports}
    account_id = Weave::Core::RateLimits.extract_account_id_from_path(req)
    "acct:#{account_id}:reports" if account_id
  end
end

