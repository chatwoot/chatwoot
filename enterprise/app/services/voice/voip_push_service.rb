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

  # The agents the ring reaches: those chosen for it with a phone on a configured platform
  # that has a push token, less any the pushes turned out not to reach
  def ringable_user_ids
    subscriptions = []
    subscriptions += apple_subscriptions.to_a if push_config.configured?(:apple)
    subscriptions += android_subscriptions if push_config.configured?(:android)
    subscriptions.select { |subscription| subscription.subscription_attributes['push_token'].present? }
                 .map(&:user_id).uniq - call.ring_state.fetch('unreached_user_ids', [])
  end

  private

  # Both platforms and every device go out at the same time, so no phone waits on another
  # device's round trip. Payloads and configuration are read here, on the job's thread and
  # connection; the threads set up the clients and make the HTTP requests.
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

  # A platform whose delivery failed as a whole, its connection included, reached nobody.
  # Each platform's client is set up on its own thread, so a slow Google token request does
  # not hold up the iPhones.
  def deliver_ring(apple, android)
    apple_sender = push_config.apple_sender(call_id: call.id, expiry_seconds: RING_EXPIRY_SECONDS) if apple.any?
    android_client = push_config.android_client_builder if android.any?
    payload = payloads.ring
    data = payloads.ring_data
    [
      deliver_in_thread(apple) { apple_sender.ring(apple, payload) },
      deliver_in_thread(android) { fcm_sender(android_client)&.deliver(android, data, 'ring') }
    ].map(&:value)
  end

  def deliver_in_thread(tokens, &)
    Thread.new { tokens.empty? ? {} : with_rails(&) || tokens.index_with(:failed) }
  end

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

  def payloads
    @payloads ||= Voice::VoipPushPayloads.new(call: call)
  end

  def push_config
    @push_config ||= Voice::VoipPushConfig.new
  end

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

  def apple_subscriptions
    NotificationSubscription.apns_voip.where(user_id: recipients.map(&:id))
  end

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

  # MARK: Android

  # nil when the client cannot be set up
  def fcm_sender(client_builder)
    platform_client('android') do
      Voice::FcmVoipSender.new(client: client_builder.call, call_id: call.id, expiry_seconds: RING_EXPIRY_SECONDS)
    end
  end
end
