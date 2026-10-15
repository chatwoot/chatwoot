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
    subscriptions = (configured?(:apple) ? apple_subscriptions.to_a : []) + (configured?(:android) ? android_subscriptions : [])
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

  # Asked before each batch after the first. The status is read past the query cache, which
  # would otherwise answer every check after the first, and the lease is renewed, so it
  # outlasts a ring of any size; neither reloads the call, which the delivery threads share.
  def keep_ringing? = Call.uncached { Call.where(id: call.id).first&.ringing? } && hold_ring_lease

  def hold_ring_lease = merge_ring_state({ 'ring_started_at' => Time.zone.now.to_i }, reload: false) || true

  # nil when the sender cannot be set up
  def apple_sender(settings) = platform_client('apple') { Voice::ApnsVoipSender.new(settings: settings, call_id: call.id) }

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
    sender = fcm_sender(*firebase_config)
    return unless sender

    forget_devices(ANDROID, gone(with_rails { sender.deliver(tokens, data, 'cancel') }.to_h))
  end

  def payloads = (@payloads ||= Voice::VoipPushPayloads.new(call: call))

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
      # A cleared bundle ID falls back to the app's, as an unset one does
      topic: "#{config('APNS_VOIP_BUNDLE_ID').presence || 'com.chatwoot.app'}.voip",
      expiry_seconds: RING_EXPIRY_SECONDS
    }
  end

  # MARK: Android

  def firebase_config = [config('FIREBASE_PROJECT_ID'), config('FIREBASE_CREDENTIALS')]

  # nil when the client cannot be set up
  def fcm_sender(project_id, credentials)
    platform_client('android') do
      client = Notification::FcmService.new(project_id, credentials).fcm_client
      Voice::FcmVoipSender.new(client: client, call_id: call.id, expiry_seconds: RING_EXPIRY_SECONDS)
    end
  end

  def config(name, default = nil) = GlobalConfigService.load(name, default)
end
