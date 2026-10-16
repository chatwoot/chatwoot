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
# the ring went. Voice::VoipPushConfig decides how each platform is reached: with the
# installation's own credentials, or through the Chatwoot Hub relay.
class Voice::VoipPushService
  pattr_initialize [:call!]

  RING_EXPIRY_SECONDS = 45
  # How long a ring under way holds the call's ring, from its start or its latest batch,
  # before another job may take it over
  RING_LEASE_SECONDS = 30
  APPLE = 'apns_voip'.freeze
  ANDROID = 'fcm'.freeze

  # The agents a call rings; see Voice::RingRecipients
  def self.recipients_for(call) = Voice::RingRecipients.new(call: call).agents

  def perform(action)
    case action
    when 'ring' then ring
    when 'cancel' then cancel
    end
  end

  # The agents the ring reaches: those it was sent to a device of, less any the pushes
  # turned out not to reach. Before the ring is prepared, those with a device it would be
  # sent to; a device registered after it is not counted.
  def ringable_user_ids
    rung = call.ring_state.fetch('rung_user_ids') { subscribed_user_ids }
    rung - call.ring_state.fetch('unreached_user_ids', [])
  end

  private

  def subscribed_user_ids
    subscriptions = (push_config.configured?(:apple) ? apple_subscriptions.to_a : []) +
                    (push_config.configured?(:android) ? android_subscriptions : [])
    subscriptions.select { |subscription| subscription.subscription_attributes['push_token'].present? }.map(&:user_id).uniq
  end

  # Both platforms and every device go out at the same time, so no phone waits on another
  # device's round trip. Payloads and configuration are read here, on the job's thread and
  # connection; the threads set up the clients and make the HTTP requests.
  #
  # The status check and the record of who is rung happen under the row lock, so a
  # terminate cannot slip between them: it either lands first and there is nothing to
  # ring, or it waits and then finds the devices to cancel. A call that stops ringing
  # while the pushes are in flight, whether answered or ended, may have its cancel
  # overtaken by the ring, so the ring is followed by a cancel of its own in that case.
  #
  # A call is rung once. A second ring job after the ring settled, such as one a retried
  # inbound call queued while the first was waiting, only replays the new-message
  # notification; one that finds the ring under way checks again once its lease is over.
  def ring
    # A settled ring's notification is replayed even once the call is over; only sending
    # needs the call still ringing
    prepared = call.with_lock { call.ringing? || ring_settled? ? prepare_ring : nil }
    return if prepared.nil?
    return Voice::VoipPushJob.set(wait: prepared.seconds).perform_later(call.id, 'ring') if prepared.is_a?(Integer)

    return replay_new_message_notification if prepared == :settled

    # A ring with no device to send to is settled all the same, so it is not taken up again
    apple, android = prepared
    apple_results, android_results = deliver_ring(apple, android)
    settle_ring(apple_results, android_results)
    # The tokens just rung are used, not the stored ones: a cancel that ran while these
    # pushes were in flight has already removed those
    cancel(android - gone(android_results)) unless call.reload.ringing?
  end

  # A platform whose delivery failed as a whole, its connection included, reached nobody.
  # Each platform's client is set up on its own thread, so a slow Google token request does
  # not hold up the iPhones.
  def deliver_ring(apple, android)
    apple_sender = platform_client('apple') { push_config.apple_sender(call_id: call.id, expiry_seconds: RING_EXPIRY_SECONDS) } if apple.any?
    android_client = push_config.android_client_builder if android.any?
    payload = payloads.ring
    data = payloads.ring_data
    [
      deliver_in_thread(apple) { apple_sender&.ring(apple, payload, proceed: -> { keep_ringing? }) },
      deliver_in_thread(android) { fcm_sender(android_client)&.deliver(android, data, 'ring', proceed: -> { keep_ringing? }) }
    ].map(&:value)
  end

  def deliver_in_thread(tokens, &)
    Thread.new { tokens.empty? ? {} : with_rails(&) || tokens.index_with(:failed) }
  end

  # Asked before each batch after the first. The status is read past the query cache, which
  # would otherwise answer every check after the first, and the lease is renewed, so it
  # outlasts a ring of any size; neither reloads the call, which the delivery threads share.
  def keep_ringing? = Call.uncached { Call.where(id: call.id).first&.ringing? } && hold_ring_lease

  def hold_ring_lease = merge_ring_state({ 'ring_started_at' => Time.zone.now.to_i }, reload: false) || true

  def devices_to_ring
    push_config.apple_environment if push_config.direct?(:apple)
    [push_config.configured?(:apple) ? apple_tokens : [], push_config.configured?(:android) ? android_tokens : []]
  end

  def cancel(tokens = nil)
    return forget_rung_devices if call.outgoing? || !push_config.configured?(:android)

    tokens ||= rung_devices[ANDROID]
    forget_rung_devices
    return if tokens.blank?

    data = payloads.cancel_data
    sender = fcm_sender(push_config.android_client_builder)
    return unless sender

    forget_devices(ANDROID, gone(with_rails { sender.deliver(tokens, data, 'cancel') }.to_h))
  end

  def payloads = (@payloads ||= Voice::VoipPushPayloads.new(call: call))

  def push_config = (@push_config ||= Voice::VoipPushConfig.new)

  # A platform whose client cannot be set up, such as when Google's token request fails,
  # is not rung; the other platform still is
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

  # MARK: recipients and devices

  # The agents recorded when the ring started, or the same choice made now for a call
  # that has none recorded; resolved once per ring so the devices rung and the agents
  # recorded are one set
  def recipients
    @recipients ||= call.ring_state['ring_recipient_ids']&.then { |ids| call.account.users.where(id: ids).to_a } || self.class.recipients_for(call)
  end

  def apple_subscriptions = NotificationSubscription.apns_voip.where(user_id: recipients.map(&:id))

  def android_subscriptions
    NotificationSubscription.fcm
                            .where(user_id: recipients.map(&:id))
                            .select { |subscription| subscription.subscription_attributes['devicePlatform'].to_s.casecmp('android').zero? }
  end

  def apple_tokens = push_tokens(apple_subscriptions)

  def android_tokens = push_tokens(android_subscriptions)

  # Each token's owner is noted as the ring is put together, since a subscription can change
  # while the pushes are in flight
  def push_tokens(subscriptions)
    subscriptions.filter_map do |subscription|
      token = subscription.subscription_attributes['push_token']
      token_owners[token] = subscription.user_id if token
      token
    end.uniq
  end

  def token_owners = (@token_owners ||= {})

  def rung_devices = call.ring_state.fetch('rung_devices', {})

  # A ring counts as done once its outcome is recorded. One under way holds the ring for
  # RING_LEASE_SECONDS, and another job meanwhile returns the seconds left to wait; one that
  # stopped after choosing whom to ring, without recording an outcome, is prepared and sent
  # again once that lease runs out.
  def ring_settled? = call.ring_state.key?('unreached_user_ids')

  def prepare_ring
    return :settled if ring_settled?

    lease_left = call.ring_state['ring_started_at'].to_i + RING_LEASE_SECONDS - Time.zone.now.to_i
    lease_left.positive? ? lease_left : remember_ring
  end

  # Records the agents chosen for this ring, those it is sent to a device of and, where there
  # are any, the devices being rung. Merged into its own column in place, so neither another ring's record nor a
  # write of `meta` erases it. Returns the device tokens by platform.
  def remember_ring
    apple, android = devices_to_ring
    rung = { 'ring_recipient_ids' => recipients.map(&:id), 'rung_user_ids' => token_owners.values.uniq,
             'ring_started_at' => Time.zone.now.to_i }
    rung['rung_devices'] = { APPLE => apple, ANDROID => android } if apple.any? || android.any?
    merge_ring_state(rung)
    [apple, android]
  end

  # The tokens are needed only until the ring is cancelled; the agents rung stay for the
  # missed-call notice
  def forget_rung_devices = Call.where(id: call.id).update_all("ring_state = ring_state - 'rung_devices'") # rubocop:disable Rails/SkipsModelValidations

  def merge_ring_state(values, reload: true)
    Call.where(id: call.id).update_all(['ring_state = ring_state || ?::jsonb', values.to_json]) # rubocop:disable Rails/SkipsModelValidations
    call.reload if reload
  end

  def gone(results) = results.filter_map { |token, outcome| token if outcome == :gone }

  # The new-message notification is held back for agents whose phone the ring reaches. Once
  # the pushes are out, the agents no push reached are recorded, and the notification runs
  # again: it reaches them, and any agent it held back before the ring was prepared who the
  # ring then left out; agents already notified for the message are skipped. Devices the
  # platforms no longer know are removed.
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

  def replay_new_message_notification = call.reload.message&.then { |message| Messages::NewMessageNotificationService.new(message: message).perform }

  # The agents none of whose devices took the ring, a device the ring stopped before sending to included
  def unreached_user_ids(results)
    token_owners.values.uniq - results.filter_map { |token, outcome| token_owners[token] if outcome == :sent }
  end

  # A device the platform no longer knows is removed so it stops costing a request per ring
  def forget_devices(type, tokens)
    return if tokens.blank?

    NotificationSubscription.where(subscription_type: type)
                            .where("subscription_attributes->>'push_token' IN (?)", tokens)
                            .destroy_all
  end

  # MARK: Android

  # nil when the client cannot be set up
  def fcm_sender(client_builder)
    platform_client('android') do
      Voice::FcmVoipSender.new(client: client_builder.call, call_id: call.id, expiry_seconds: RING_EXPIRY_SECONDS)
    end
  end
end
