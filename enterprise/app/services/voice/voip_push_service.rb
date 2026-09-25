# Rings the agents' phones for an inbound call, and tells Android phones when the ring
# is over. A phone with no live socket only learns about a call this way.
#
# iOS is rung with an APNs VoIP push (PushKit), which the system delivers even when the
# app is not running, and which the app reports to CallKit. iOS is never sent a cancel:
# the system requires every VoIP push to report a call, so a cancel for a ring the phone
# has already ended would surface a phantom call. The woken app connects its socket and
# learns from the voice_call events that the call was answered elsewhere, declined or
# dropped; its own ring timeout covers the rest.
#
# Android is rung with a high-priority FCM data message and, because nothing on the
# phone holds the ring but a notification and the app's own screen, is sent a plain
# data message when the call leaves ringing.
#
# The devices rung are kept on `call.meta['rung_devices']` so a cancel goes only where
# the ring went. Configuration lives in the installation config: APNS_VOIP_KEY (the .p8
# contents), APNS_VOIP_KEY_ID, APNS_VOIP_TEAM_ID, APNS_VOIP_BUNDLE_ID,
# APNS_VOIP_ENVIRONMENT, plus the existing FIREBASE_PROJECT_ID and FIREBASE_CREDENTIALS.
class Voice::VoipPushService
  pattr_initialize [:call!]

  RING_EXPIRY_SECONDS = 45
  APPLE = 'apns_voip'.freeze
  ANDROID = 'fcm'.freeze
  # Android deliveries in flight at once per call
  ANDROID_BATCH_SIZE = 20

  def perform(action)
    case action
    when 'ring' then ring
    when 'cancel' then cancel
    end
  end

  private

  # Both platforms and every device go out at the same time, so no phone waits on another
  # device's round trip. Network work runs in the threads; the database is touched only here.
  # The call is re-read first: a terminate that overtook the ring leaves nothing to ring for.
  def ring
    return unless call.reload.ringing?

    apple, android = devices_to_ring
    return if apple.empty? && android.empty?

    remember_rung_devices(apple, android)
    stale_apple, stale_android = [
      Thread.new { with_rails { ring_apple(apple) } },
      Thread.new { with_rails { deliver_android_all(android, ring_data, 'ring') } }
    ].map(&:value)
    forget_devices(APPLE, stale_apple)
    forget_devices(ANDROID, stale_android)
  end

  def devices_to_ring
    [
      apple_configured? ? apple_tokens : [],
      firebase_configured? ? android_tokens : []
    ]
  end

  def cancel
    return if call.outgoing?
    return unless firebase_configured?

    tokens = rung_devices[ANDROID]
    return if tokens.blank?

    forget_devices(ANDROID, with_rails { deliver_android_all(tokens, cancel_data, 'cancel') })
  end

  def with_rails(&)
    Rails.application.executor.wrap(&)
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] call #{call.id} failed: #{e.class}: #{e.message}")
    nil
  end

  # MARK: recipients and devices

  # The assignee if the conversation has one, otherwise everyone who could be assigned
  # the inbox. Presence is not consulted: a locked phone is offline on the socket and
  # is exactly the device this push exists for.
  def recipients
    assignee = call.conversation.assignee
    return [assignee] if assignee

    call.inbox.assignable_agents
  end

  def apple_tokens
    NotificationSubscription.apns_voip
                            .where(user_id: recipients.map(&:id))
                            .filter_map { |subscription| subscription.subscription_attributes['push_token'] }
                            .uniq
  end

  def android_tokens
    NotificationSubscription.fcm
                            .where(user_id: recipients.map(&:id))
                            .select { |subscription| subscription.subscription_attributes['devicePlatform'].to_s.casecmp('android').zero? }
                            .filter_map { |subscription| subscription.subscription_attributes['push_token'] }
                            .uniq
  end

  def rung_devices
    (call.meta || {}).fetch('rung_devices', {})
  end

  # Merged into the column in place, so a webhook writing other meta keys meanwhile keeps them
  def remember_rung_devices(apple, android)
    rung = { 'rung_devices' => { APPLE => apple, ANDROID => android } }
    Call.where(id: call.id).update_all(["meta = COALESCE(meta, '{}'::jsonb) || ?::jsonb", rung.to_json]) # rubocop:disable Rails/SkipsModelValidations
    call.reload
  end

  # A device the platform no longer knows is removed so it stops costing a request per ring
  def forget_devices(type, tokens)
    return if tokens.blank?

    NotificationSubscription.where(subscription_type: type)
                            .where("subscription_attributes->>'push_token' IN (?)", tokens)
                            .destroy_all
  end

  # MARK: payloads

  def base_payload
    {
      call_id: call.provider_call_id,
      id: call.id,
      provider: call.provider,
      direction: call.direction_label,
      conversation_id: call.conversation_id,
      inbox_id: call.inbox_id,
      account_id: call.account_id
    }
  end

  def ring_payload
    contact = call.contact
    base_payload.merge(
      type: 'voice_call.incoming',
      caller: { name: contact&.name, phone: contact&.phone_number, avatar: contact&.avatar_url.presence },
      inbox_name: call.inbox.name
    )
  end

  # FCM data values must all be strings, and the caller travels as JSON
  def ring_data
    data = ring_payload.except(:caller).transform_keys(&:to_s).transform_values(&:to_s)
    data['caller'] = ring_payload[:caller].to_json
    data
  end

  def cancel_data
    base_payload.merge(type: 'voice_call.cancel', reason: call.status).transform_keys(&:to_s).transform_values(&:to_s)
  end

  # MARK: Apple

  def apple_configured?
    config('APNS_VOIP_KEY').present? && config('APNS_VOIP_KEY_ID').present? && config('APNS_VOIP_TEAM_ID').present?
  end

  # Returns the tokens Apple reported as gone
  def ring_apple(tokens)
    return [] if tokens.empty?

    payload = ring_payload
    connection = apple_connection
    tokens.select { |token| deliver_apple(connection, token, payload) == :gone }
  ensure
    connection&.close
  end

  def apple_connection
    production = config('APNS_VOIP_ENVIRONMENT', 'production') == 'production'
    Apnotic::Connection.new(
      url: production ? Apnotic::APPLE_PRODUCTION_SERVER_URL : Apnotic::APPLE_DEVELOPMENT_SERVER_URL,
      auth_method: :token,
      cert_path: StringIO.new(config('APNS_VOIP_KEY')),
      key_id: config('APNS_VOIP_KEY_ID'),
      team_id: config('APNS_VOIP_TEAM_ID')
    )
  end

  def apple_notification(token, payload)
    Apnotic::Notification.new(token).tap do |notification|
      notification.topic = "#{config('APNS_VOIP_BUNDLE_ID', 'com.chatwoot.app')}.voip"
      notification.push_type = 'voip'
      notification.priority = 10
      notification.expiration = Time.now.to_i + RING_EXPIRY_SECONDS
      notification.custom_payload = payload
    end
  end

  def deliver_apple(connection, token, payload)
    response = connection.push(apple_notification(token, payload))
    status = response ? response.status.to_s : 'no response'
    Rails.logger.info("[VOIP PUSH] apple ring call #{call.id} to #{token[0, 8]}… status=#{status} #{response&.body}")
    status == '410' ? :gone : :sent
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] apple ring call #{call.id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end

  # MARK: Android

  def firebase_configured?
    config('FIREBASE_PROJECT_ID').present? && config('FIREBASE_CREDENTIALS').present?
  end

  # Returns the tokens Firebase reported as unregistered
  def deliver_android_all(tokens, data, kind)
    return [] if tokens.empty?

    client = Notification::FcmService.new(config('FIREBASE_PROJECT_ID'), config('FIREBASE_CREDENTIALS')).fcm_client
    tokens.each_slice(ANDROID_BATCH_SIZE).flat_map do |batch|
      batch.map { |token| Thread.new { with_rails { deliver_android(client, token, data, kind) } } }
           .map(&:value)
           .zip(batch)
           .filter_map { |result, token| token if result == :gone }
    end
  end

  def deliver_android(client, token, data, kind)
    response = client.send_v1(
      token: token,
      data: data,
      android: { priority: 'high', ttl: "#{RING_EXPIRY_SECONDS}s" }
    )
    Rails.logger.info("[VOIP PUSH] android #{kind} call #{call.id} to #{token[0, 8]}… status=#{response[:status_code]}")
    response[:status_code] == 404 && response[:body].to_s.include?('UNREGISTERED') ? :gone : :sent
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] android #{kind} call #{call.id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end

  def config(name, default = nil)
    GlobalConfigService.load(name, default)
  end
end
