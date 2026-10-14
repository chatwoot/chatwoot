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
  # How long a batch of Android pushes may take; the FCM client sets no timeout of its own.
  # A push still waiting then is stopped and counts as failed.
  ANDROID_PUSH_TIMEOUT_SECONDS = 10

  # The agents a call rings; see Voice::RingRecipients
  def self.recipients_for(call) = Voice::RingRecipients.new(call: call).agents

  def perform(action)
    case action
    when 'ring' then ring
    when 'cancel' then cancel
    end
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

    stale_apple, stale_android = deliver_ring(apple, android)
    forget_devices(APPLE, stale_apple)
    forget_devices(ANDROID, stale_android)
    # The tokens just rung are used, not the stored ones: a cancel that ran while these
    # pushes were in flight has already removed those
    cancel(android - stale_android.to_a) unless call.reload.ringing?
  end

  # Each platform's client is set up on its own thread, so a slow Google token request does
  # not hold up the iPhones
  def deliver_ring(apple, android)
    settings = apple_settings if apple.any?
    firebase = firebase_config if android.any?
    payload = payloads.ring
    data = payloads.ring_data
    [
      Thread.new { with_rails { apple.any? ? ring_apple(settings, apple, payload) : [] } },
      Thread.new { with_rails { android.any? ? ring_android(firebase, android, data) : [] } }
    ].map(&:value)
  end

  def ring_apple(settings, tokens, payload)
    sender = platform_client('apple') { Voice::ApnsVoipSender.new(settings: settings, call_id: call.id) }
    sender ? sender.ring(tokens, payload, proceed: -> { still_ringing? }) : []
  end

  def ring_android(firebase, tokens, data)
    client = platform_client('android') { fcm_client(*firebase) }
    return [] unless client

    deliver_android_all(client, tokens, data, 'ring', proceed: -> { still_ringing? })
  end

  # Read past the query cache, which would otherwise answer every check after the first
  def still_ringing? = Call.uncached { Call.where(id: call.id).first&.ringing? }

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
    client = platform_client('android') { fcm_client(*firebase_config) }
    return unless client

    forget_devices(ANDROID, with_rails { deliver_android_all(client, tokens, data, 'cancel') })
  end

  # A platform whose client cannot be set up, such as when Google's token request fails,
  # is not rung; the other platform still is
  def platform_client(platform)
    yield
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] call #{call.id}: #{platform} client failed: #{e.class}: #{e.message}")
    nil
  end

  def payloads = (@payloads ||= Voice::VoipPushPayloads.new(call: call))

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

  def fcm_client(project_id, credentials)
    Notification::FcmService.new(project_id, credentials).fcm_client
  end

  # Returns the tokens Firebase reported as unregistered. `proceed` is asked before each batch
  # after the first, and the remaining batches are skipped once it returns false.
  def deliver_android_all(client, tokens, data, kind, proceed: -> { true })
    tokens.each_slice(ANDROID_BATCH_SIZE).with_index.each_with_object([]) do |(batch, index), gone|
      break gone if index.positive? && !proceed.call

      gone.concat(deliver_android_batch(client, batch, data, kind))
    end
  end

  def deliver_android_batch(client, batch, data, kind)
    threads = batch.map { |token| Thread.new { with_rails { deliver_android(client, token, data, kind) } } }
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + ANDROID_PUSH_TIMEOUT_SECONDS
    outcomes = threads.map { |thread| finish_by(thread, deadline) }
    batch.zip(outcomes).filter_map { |token, outcome| token if outcome == :gone }
  end

  # A push still waiting at the deadline is stopped, so it neither lingers nor lands after
  # the cancel that follows a ring
  def finish_by(thread, deadline)
    return thread.value if thread.join([deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0].max)

    thread.kill
    :failed
  end

  def deliver_android(client, token, data, kind)
    # One collapse key per call, so a cancel queued for an offline phone replaces the ring
    # rather than arriving before it
    android = { priority: 'high', ttl: "#{RING_EXPIRY_SECONDS}s", collapse_key: "voice_call_#{call.id}" }
    response = client.send_v1(token: token, data: data, android: android)
    outcome = android_outcome(response)
    Rails.logger.public_send(outcome == :failed ? :error : :info,
                             "[VOIP PUSH] android #{kind} call #{call.id} to #{token[0, 8]}… status=#{response[:status_code]}")
    outcome
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] android #{kind} call #{call.id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end

  # Only a 2xx response delivered the message; a rejection such as bad credentials or a
  # Firebase outage leaves the phone silent and is a failure
  def android_outcome(response)
    return :sent if response[:status_code].to_i.between?(200, 299)

    response[:status_code] == 404 && response[:body].to_s.include?('UNREGISTERED') ? :gone : :failed
  end

  def config(name, default = nil) = GlobalConfigService.load(name, default)
end
