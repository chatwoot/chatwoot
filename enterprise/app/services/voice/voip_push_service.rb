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

  # The agents the ring reaches: those chosen for it with a phone on a configured platform,
  # less any the pushes turned out not to reach
  def ringable_user_ids
    subscriptions = []
    subscriptions += apple_subscriptions.to_a if configured?(:apple)
    subscriptions += android_subscriptions if configured?(:android)
    subscriptions.map(&:user_id).uniq - call.ring_state.fetch('unreached_user_ids', [])
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

    apple_results, android_results = deliver_ring(apple, android)
    settle_ring(apple_results, android_results)
    # The tokens just rung are used, not the stored ones: a cancel that ran while these
    # pushes were in flight has already removed those
    cancel(android - gone(android_results)) unless call.reload.ringing?
  end

  # A platform whose delivery failed as a whole, its connection included, reached nobody
  def deliver_ring(apple, android)
    apple_sender = Voice::ApnsVoipSender.new(settings: apple_settings, call_id: call.id) if apple.any?
    android_sender = fcm_sender if android.any?
    payload = payloads.ring
    data = payloads.ring_data
    [
      deliver_in_thread(apple) { apple_sender.ring(apple, payload) },
      deliver_in_thread(android) { android_sender.deliver(android, data, 'ring') }
    ].map(&:value)
  end

  def deliver_in_thread(tokens, &)
    Thread.new { tokens.empty? ? {} : with_rails(&) || tokens.index_with(:failed) }
  end

  def devices_to_ring
    apple_environment if configured?(:apple)
    [configured?(:apple) ? apple_tokens : [], configured?(:android) ? android_tokens : []]
  end

  def cancel(tokens = nil)
    return forget_rung_devices if call.outgoing? || !configured?(:android)

    tokens ||= rung_devices[ANDROID]
    forget_rung_devices
    return if tokens.blank?

    data = payloads.cancel_data
    sender = fcm_sender
    forget_devices(ANDROID, gone(with_rails { sender.deliver(tokens, data, 'cancel') }.to_h))
  end

  def payloads
    @payloads ||= Voice::VoipPushPayloads.new(call: call)
  end

  def with_rails(&)
    Rails.application.executor.wrap(&)
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] call #{call.id} failed: #{e.class}: #{e.message}")
    nil
  end

  # MARK: recipients and devices

  # The agents recorded when the ring started, or the same choice made now for a call
  # that has none recorded; resolved once per ring so the devices rung and the agents
  # recorded are one set
  def recipients
    @recipients ||= call.ring_state['ring_recipient_ids']&.then { |ids| call.account.users.where(id: ids).to_a } || self.class.recipients_for(call)
  end

  def apple_subscriptions
    NotificationSubscription.apns_voip.where(user_id: recipients.map(&:id))
  end

  def android_subscriptions
    NotificationSubscription.fcm
                            .where(user_id: recipients.map(&:id))
                            .select { |subscription| subscription.subscription_attributes['devicePlatform'].to_s.casecmp('android').zero? }
  end

  def apple_tokens
    push_tokens(apple_subscriptions)
  end

  def android_tokens
    push_tokens(android_subscriptions)
  end

  # Each token's owner is noted as the ring is put together, since a subscription can change
  # while the pushes are in flight
  def push_tokens(subscriptions)
    subscriptions.filter_map do |subscription|
      token = subscription.subscription_attributes['push_token']
      token_owners[token] = subscription.user_id if token
      token
    end.uniq
  end

  def token_owners
    @token_owners ||= {}
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
    merge_ring_state(rung)
    [apple, android]
  end

  # The tokens are needed only until the ring is cancelled; the agents rung stay for the
  # missed-call notice
  def forget_rung_devices
    Call.where(id: call.id).update_all("ring_state = ring_state - 'rung_devices'") # rubocop:disable Rails/SkipsModelValidations
  end

  def merge_ring_state(values)
    Call.where(id: call.id).update_all(['ring_state = ring_state || ?::jsonb', values.to_json]) # rubocop:disable Rails/SkipsModelValidations
    call.reload
  end

  def gone(results) = results.filter_map { |token, outcome| token if outcome == :gone }

  # The new-message notification is held back for agents whose phone the ring reaches. Once
  # the pushes are out, the agents no push reached are recorded, and the notification goes
  # to them; agents already notified for the message are skipped. Devices the platforms no
  # longer know are removed.
  def settle_ring(apple_results, android_results)
    unreached = unreached_user_ids(apple_results.merge(android_results))
    forget_devices(APPLE, gone(apple_results))
    forget_devices(ANDROID, gone(android_results))
    return if unreached.empty?

    merge_ring_state('unreached_user_ids' => unreached)
    message = call.reload.message
    Messages::NewMessageNotificationService.new(message: message).perform if message
  end

  # The agents none of whose devices took the ring
  def unreached_user_ids(results)
    owners = results.keys.filter_map { |token| [token_owners[token], token] if token_owners[token] }
    owners.map(&:first).uniq - owners.filter_map { |user_id, token| user_id if results[token] == :sent }
  end

  # A device the platform no longer knows is removed so it stops costing a request per ring
  def forget_devices(type, tokens)
    return if tokens.blank?

    NotificationSubscription.where(subscription_type: type)
                            .where("subscription_attributes->>'push_token' IN (?)", tokens)
                            .destroy_all
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

  def fcm_sender
    client = Notification::FcmService.new(config('FIREBASE_PROJECT_ID'), config('FIREBASE_CREDENTIALS')).fcm_client
    Voice::FcmVoipSender.new(client: client, call_id: call.id, expiry_seconds: RING_EXPIRY_SECONDS)
  end

  def config(name, default = nil)
    GlobalConfigService.load(name, default)
  end
end
