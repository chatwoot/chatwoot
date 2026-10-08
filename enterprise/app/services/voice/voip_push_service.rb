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
# The agents and devices rung are kept on `call.ring_state` so a cancel goes only where
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

  # The agents a call rings: the assignee if the conversation has one, otherwise everyone
  # who could be assigned the inbox, keeping only agents whose status is online, as the
  # web does. Socket presence is not consulted: a locked phone is offline on the socket
  # and is exactly the device this push exists for.
  def self.recipients_for(call)
    candidates = call.conversation.assignee.then { |assignee| assignee ? [assignee] : call.inbox.assignable_agents.to_a }
    online_ids = AccountUser.where(account_id: call.account_id, availability: :online).pluck(:user_id)
    candidates.select { |user| online_ids.include?(user.id) }
  end

  def perform(action)
    case action
    when 'ring' then ring
    when 'cancel' then cancel
    end
  end

  private

  # Both platforms and every device go out at the same time, so no phone waits on another
  # device's round trip. Payloads, configuration and clients are built here, on the job's
  # thread and connection; the threads only make the HTTP requests.
  #
  # The status check and the record of who is rung happen under the row lock, so a
  # terminate cannot slip between them: it either lands first and there is nothing to
  # ring, or it waits and then finds the devices to cancel. A call that stops ringing
  # while the pushes are in flight, whether answered or ended, may have its cancel
  # overtaken by the ring, so the ring is followed by a cancel of its own in that case.
  def ring
    apple, android = call.with_lock { call.ringing? ? remember_ring : nil }
    return if apple.nil? || (apple.empty? && android.empty?)

    stale_apple, stale_android = deliver_ring(apple, android)
    forget_devices(APPLE, stale_apple)
    forget_devices(ANDROID, stale_android)
    cancel unless call.reload.ringing?
  end

  def deliver_ring(apple, android)
    sender = Voice::ApnsVoipSender.new(settings: apple_settings, call_id: call.id) if apple.any?
    client = fcm_client if android.any?
    payload = ring_payload
    data = ring_data
    [
      Thread.new { with_rails { sender ? sender.ring(apple, payload) : [] } },
      Thread.new { with_rails { deliver_android_all(client, android, data, 'ring') } }
    ].map(&:value)
  end

  def devices_to_ring
    apple_environment if configured?(:apple)
    [configured?(:apple) ? apple_tokens : [], configured?(:android) ? android_tokens : []]
  end

  def cancel
    return forget_rung_devices if call.outgoing? || !configured?(:android)

    tokens = rung_devices[ANDROID]
    forget_rung_devices
    return if tokens.blank?

    data = cancel_data
    client = fcm_client
    forget_devices(ANDROID, with_rails { deliver_android_all(client, tokens, data, 'cancel') })
  end

  def with_rails(&)
    Rails.application.executor.wrap(&)
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] call #{call.id} failed: #{e.class}: #{e.message}")
    nil
  end

  # MARK: recipients and devices

  # Resolved once per ring so the devices rung and the agents recorded are one set
  def recipients
    @recipients ||= self.class.recipients_for(call)
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
    call.ring_state.fetch('rung_devices', {})
  end

  # Records the agents chosen for this ring and, where there are any, the devices being
  # rung. Merged into its own column in place, so neither another ring's record nor a
  # write of `meta` erases it. Returns the device tokens by platform.
  def remember_ring
    apple, android = devices_to_ring
    rung = { 'ring_recipient_ids' => recipients.map(&:id) }
    rung['rung_devices'] = { APPLE => apple, ANDROID => android } if apple.any? || android.any?
    Call.where(id: call.id).update_all(['ring_state = ring_state || ?::jsonb', rung.to_json]) # rubocop:disable Rails/SkipsModelValidations
    call.reload
    [apple, android]
  end

  # The tokens are needed only until the ring is cancelled; the agents rung stay for the
  # missed-call notice
  def forget_rung_devices
    Call.where(id: call.id).update_all("ring_state = ring_state - 'rung_devices'") # rubocop:disable Rails/SkipsModelValidations
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
      # The app addresses conversations by their display id
      conversation_id: call.conversation.display_id,
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

  APNS_ENVIRONMENTS = %w[development production].freeze

  CREDENTIALS = {
    apple: %w[APNS_VOIP_KEY APNS_VOIP_KEY_ID APNS_VOIP_TEAM_ID],
    android: %w[FIREBASE_PROJECT_ID FIREBASE_CREDENTIALS]
  }.freeze

  # A platform is rung only with every credential set. Some but not all set is a broken
  # deployment rather than an opted-out one, so it is reported; the other platform still rings.
  def configured?(platform)
    @configured ||= {}
    return @configured[platform] if @configured.key?(platform)

    names = CREDENTIALS[platform]
    missing = names.select { |name| config(name).blank? }
    if missing.any? && missing.size < names.size
      ChatwootExceptionTracker.new(ArgumentError.new("#{platform} push is partly configured; missing #{missing.join(', ')}")).capture_exception
    end
    @configured[platform] = missing.empty?
  end

  # A misspelt environment would quietly send App Store tokens to the sandbox, so it fails the job
  def apple_environment
    environment = config('APNS_VOIP_ENVIRONMENT', 'production')
    return environment if APNS_ENVIRONMENTS.include?(environment)

    raise ArgumentError, "APNS_VOIP_ENVIRONMENT must be one of #{APNS_ENVIRONMENTS.join(', ')}, got #{environment.inspect}"
  end

  # Everything the Apple sender needs, read from the configuration before the delivery
  # threads start
  def apple_settings
    {
      production: apple_environment == 'production',
      key: config('APNS_VOIP_KEY'),
      key_id: config('APNS_VOIP_KEY_ID'),
      team_id: config('APNS_VOIP_TEAM_ID'),
      topic: "#{config('APNS_VOIP_BUNDLE_ID', 'com.chatwoot.app')}.voip",
      expiry_seconds: RING_EXPIRY_SECONDS
    }
  end

  # MARK: Android

  def fcm_client
    Notification::FcmService.new(config('FIREBASE_PROJECT_ID'), config('FIREBASE_CREDENTIALS')).fcm_client
  end

  # Returns the tokens Firebase reported as unregistered
  def deliver_android_all(client, tokens, data, kind)
    return [] if tokens.empty?

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
