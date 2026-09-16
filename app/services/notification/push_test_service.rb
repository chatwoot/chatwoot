class Notification::PushTestService
  pattr_initialize [:user!, :subscription_ids!, :title, :body]

  DEFAULT_TITLE = '%<installation_name>s notification test'.freeze
  DEFAULT_BODY = 'This is a test from our team to check notification delivery on your device. No action needed.'.freeze

  def self.default_title
    format(DEFAULT_TITLE, installation_name: GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot'))
  end

  def self.default_body
    DEFAULT_BODY
  end

  def perform
    selected_subscriptions.map { |subscription| test_send(subscription) }
  end

  private

  def resolved_title
    title.presence || self.class.default_title
  end

  def resolved_body
    body.presence || self.class.default_body
  end

  def selected_subscriptions
    user.notification_subscriptions.where(id: subscription_ids).order(:id)
  end

  def test_send(subscription)
    if subscription.browser_push?
      test_browser_push(subscription)
    elsif subscription.fcm?
      test_fcm(subscription)
    else
      result(subscription, subscription.subscription_type.to_s, :skipped, 'Unknown subscription type')
    end
  end

  def test_browser_push(subscription)
    return result(subscription, 'browser_push', :skipped, 'VAPID keys not configured') unless VapidService.public_key

    WebPush.payload_send(**browser_push_payload(subscription))
    result(subscription, 'browser_push', :success, 'Web push accepted by endpoint')
  rescue StandardError => e
    result(subscription, 'browser_push', :failure, "#{e.class.name}: #{e.message}")
  end

  def test_fcm(subscription)
    if firebase_credentials_present?
      test_fcm_direct(subscription)
    elsif chatwoot_hub_enabled?
      test_fcm_via_hub(subscription)
    else
      result(subscription, 'fcm', :skipped, 'No Firebase credentials and push relay disabled')
    end
  end

  def test_fcm_direct(subscription)
    fcm_service = Notification::FcmService.new(
      GlobalConfigService.load('FIREBASE_PROJECT_ID', nil),
      GlobalConfigService.load('FIREBASE_CREDENTIALS', nil)
    )
    response = fcm_service.fcm_client.send_v1(fcm_options(subscription))
    status_code = response[:status_code].to_i
    status = status_code.between?(200, 299) ? :success : :failure
    result(subscription, 'fcm', status, "HTTP #{status_code} — #{response[:body]}")
  rescue StandardError => e
    result(subscription, 'fcm', :failure, "#{e.class.name}: #{e.message}")
  end

  def test_fcm_via_hub(subscription)
    response = ChatwootHub.send_push_with_response(fcm_options(subscription))
    result(subscription, 'fcm_via_hub', :success, "HTTP #{response.code} — #{response.body}")
  rescue RestClient::ExceptionWithResponse => e
    result(subscription, 'fcm_via_hub', :failure, "HTTP #{e.response&.code} — #{e.response&.body}")
  rescue StandardError => e
    result(subscription, 'fcm_via_hub', :failure, "#{e.class.name}: #{e.message}")
  end

  def firebase_credentials_present?
    GlobalConfigService.load('FIREBASE_PROJECT_ID', nil) && GlobalConfigService.load('FIREBASE_CREDENTIALS', nil)
  end

  def chatwoot_hub_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PUSH_RELAY_SERVER', true))
  end

  def browser_push_payload(subscription)
    {
      message: JSON.generate(
        title: resolved_title,
        tag: "super_admin_test_#{Time.zone.now.to_i}",
        url: ENV.fetch('FRONTEND_URL', 'https://app.chatwoot.com')
      ),
      endpoint: subscription.subscription_attributes['endpoint'],
      p256dh: subscription.subscription_attributes['p256dh'],
      auth: subscription.subscription_attributes['auth'],
      vapid: {
        subject: ENV.fetch('FRONTEND_URL', 'https://app.chatwoot.com'),
        public_key: VapidService.public_key,
        private_key: VapidService.private_key
      },
      ssl_timeout: 5,
      open_timeout: 5,
      read_timeout: 5
    }
  end

  def fcm_options(subscription)
    {
      'token': subscription.subscription_attributes['push_token'],
      'data': { payload: { data: { notification: { type: 'test' } } }.to_json },
      'notification': { title: resolved_title, body: resolved_body },
      'android': { priority: 'high' },
      'apns': { payload: { aps: { sound: 'default', category: Time.zone.now.to_i.to_s } } },
      'fcm_options': { analytics_label: 'SuperAdminTest' }
    }
  end

  def result(subscription, type, status, message)
    attrs = subscription.subscription_attributes || {}
    {
      id: subscription.id,
      type: type.to_s,
      device: device_label(subscription, attrs),
      token_tail: token_tail(subscription, attrs),
      status: status,
      message: message
    }
  end

  def device_label(subscription, attrs)
    if subscription.browser_push?
      endpoint_host(attrs['endpoint'].to_s)
    else
      attrs['device_id'].present? ? "…#{attrs['device_id'].to_s.last(6)}" : '—'
    end
  end

  def endpoint_host(endpoint)
    return '—' if endpoint.blank?

    URI.parse(endpoint).host.presence || endpoint
  rescue URI::InvalidURIError
    endpoint
  end

  def token_tail(subscription, attrs)
    if subscription.browser_push?
      endpoint = attrs['endpoint'].to_s
      endpoint.present? ? "…#{endpoint.last(6)}" : '—'
    else
      attrs['push_token'].present? ? "…#{attrs['push_token'].to_s.last(6)}" : '—'
    end
  end
end
