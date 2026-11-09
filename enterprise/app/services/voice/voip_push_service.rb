class Voice::VoipPushService
  include Voice::VoipPushConfiguration

  pattr_initialize [:call!]

  RING_LEASE_SECONDS = 30
  APPLE = 'apns_voip'.freeze
  ANDROID = 'fcm'.freeze

  def self.recipients_for(call) = Voice::RingRecipients.new(inbox: call.inbox, conversation: call.conversation).agents

  def perform(action)
    case action
    when 'ring' then ring
    when 'cancel' then cancel
    end
  end

  def ringable_user_ids
    rung = call.ring_state.fetch('rung_user_ids') { subscribed_user_ids }
    rung - call.ring_state.fetch('unreached_user_ids', [])
  end

  private

  def subscribed_user_ids
    subscriptions = (configured?(:apple) ? apple_subscriptions.to_a : []) + (configured?(:android) ? android_subscriptions : [])
    subscriptions.select { |subscription| subscription.subscription_attributes['push_token'].present? }.map(&:user_id).uniq
  end

  # The status check and recipient snapshot share a lock with call termination.
  def ring
    prepared = call.with_lock { call.ringing? || ring_settled? ? prepare_ring : nil }
    return if prepared.nil?
    return Voice::VoipPushJob.set(wait: prepared.seconds).perform_later(call.id, 'ring') if prepared.is_a?(Integer)

    return replay_new_message_notification if prepared == :settled

    apple, android = prepared
    apple_results, android_results = deliver_ring(apple, android)
    settle_ring(apple_results, android_results)
    # A concurrent cancel can clear stored tokens before these pushes finish.
    cancel(android - gone(android_results)) unless call.reload.ringing?
  end

  # Payloads and configuration use the job's database connection.
  # Platforms initialize independently so slow token requests do not block each other.
  def deliver_ring(apple, android)
    settings = apple_settings if apple.any?
    firebase = firebase_config if android.any?
    payload = payloads.ring
    data = payloads.ring_data
    [
      deliver_in_thread(apple) { apple_sender(settings)&.ring(apple, payload, proceed: -> { keep_ringing? }) },
      deliver_in_thread(android) { fcm_sender(*firebase)&.deliver(android, data, 'ring', proceed: -> { keep_ringing? }) }
    ].map(&:value)
  end

  def deliver_in_thread(tokens, &)
    Thread.new { tokens.empty? ? {} : with_rails(&) || tokens.index_with(:failed) }
  end

  # Batch checks bypass the query cache without reloading the Call shared by delivery threads.
  def keep_ringing?
    Call.uncached { Call.where(id: call.id).first&.ringing? } && hold_ring_lease
  end

  def hold_ring_lease
    merge_ring_state({ 'ring_started_at' => Time.zone.now.to_i }, reload: false) || true
  end

  def apple_sender(settings)
    platform_client('apple') { Voice::ApnsVoipSender.new(settings: settings, call_id: call.id) }
  end

  def devices_to_ring
    apple_environment if configured?(:apple)
    [configured?(:apple) ? apple_tokens : [], configured?(:android) ? android_tokens : []]
  end

  # iOS requires every VoIP push to report a call, so only Android receives cancel pushes.
  def cancel(tokens = nil)
    return forget_rung_devices if call.outgoing? || !configured?(:android)

    tokens ||= rung_devices[ANDROID]
    forget_rung_devices
    return if tokens.blank?

    data = payloads.cancel_data
    sender = fcm_sender(*firebase_config)
    return unless sender

    forget_devices(ANDROID, gone(with_rails { sender.deliver(tokens, data, 'cancel') }.to_h))
  end

  def payloads
    (@payloads ||= Voice::VoipPushPayloads.new(call: call))
  end

  def platform_client(platform)
    yield
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] call #{call.id}: #{platform} client failed: #{e.class}: #{e.message}")
    nil
  end

  def with_rails(&)
    Rails.application.executor.wrap(&)
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] call #{call.id} failed: #{e.class}: #{e.message}")
    nil
  end

  # Recipients stay fixed for a ring even if the conversation is reassigned.
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

  # Token ownership can change while pushes are in flight.
  def push_tokens(subscriptions)
    subscriptions.filter_map do |subscription|
      token = subscription.subscription_attributes['push_token']
      token_owners[token] = subscription.user_id if token
      token
    end.uniq
  end

  def token_owners
    (@token_owners ||= {})
  end

  def rung_devices
    call.ring_state.fetch('rung_devices', {})
  end

  # A recorded delivery outcome prevents duplicate rings; an expired lease permits recovery.
  def ring_settled?
    call.ring_state.key?('unreached_user_ids')
  end

  def prepare_ring
    return :settled if ring_settled?

    lease_left = call.ring_state['ring_started_at'].to_i + RING_LEASE_SECONDS - Time.zone.now.to_i
    lease_left.positive? ? lease_left : remember_ring
  end

  # Ring state is merged atomically to preserve concurrent updates.
  def remember_ring
    apple, android = devices_to_ring
    rung = { 'ring_recipient_ids' => recipients.map(&:id), 'rung_user_ids' => token_owners.values.uniq,
             'ring_started_at' => Time.zone.now.to_i }
    rung['rung_devices'] = { APPLE => apple, ANDROID => android } if apple.any? || android.any?
    merge_ring_state(rung)
    [apple, android]
  end

  def forget_rung_devices
    Call.where(id: call.id).update_all("ring_state = ring_state - 'rung_devices'") # rubocop:disable Rails/SkipsModelValidations
  end

  def merge_ring_state(values, reload: true)
    Call.where(id: call.id).update_all(['ring_state = ring_state || ?::jsonb', values.to_json]) # rubocop:disable Rails/SkipsModelValidations
    call.reload if reload
  end

  def gone(results)
    results.filter_map { |token, outcome| token if outcome == :gone }
  end

  # Replaying notifications restores alerts for agents whose devices did not receive the ring.
  def settle_ring(apple_results, android_results)
    unreached = unreached_user_ids(apple_results.merge(android_results))
    forget_devices(APPLE, gone(apple_results))
    forget_devices(ANDROID, gone(android_results))
    record_unreached(unreached)
    replay_new_message_notification
  end

  # An agent another attempt at this ring already reached stays reached
  def record_unreached(unreached)
    call.with_lock do
      earlier = call.ring_state['unreached_user_ids']
      merge_ring_state({ 'unreached_user_ids' => earlier ? unreached & earlier : unreached })
    end
  end

  def replay_new_message_notification
    call.reload.message&.then { |message| Messages::NewMessageNotificationService.new(message: message).perform }
  end

  def unreached_user_ids(results)
    token_owners.values.uniq - results.filter_map { |token, outcome| token_owners[token] if outcome == :sent }
  end

  def forget_devices(type, tokens)
    return if tokens.blank?

    NotificationSubscription.where(subscription_type: type)
                            .where("subscription_attributes->>'push_token' IN (?)", tokens)
                            .destroy_all
  end

  def fcm_sender(project_id, credentials)
    platform_client('android') do
      client = Notification::FcmService.new(project_id, credentials).fcm_client
      Voice::FcmVoipSender.new(client: client, call_id: call.id, expiry_seconds: RING_EXPIRY_SECONDS)
    end
  end
end
