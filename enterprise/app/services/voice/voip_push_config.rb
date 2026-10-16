# How each platform's call pushes are sent. With every credential set, the installation sends
# them itself: APNS_VOIP_KEY, APNS_VOIP_KEY_ID and APNS_VOIP_TEAM_ID (with APNS_VOIP_BUNDLE_ID
# and APNS_VOIP_ENVIRONMENT) for iPhones, FIREBASE_PROJECT_ID and FIREBASE_CREDENTIALS for
# Android. Otherwise, with ENABLE_PUSH_RELAY_SERVER on and CHATWOOT_VOICE_RELAY_SECRET set,
# they go through the Chatwoot Hub voice relay. The hub issues that secret when it approves the
# installation, and reaches only phones the installation registered with it
# (Voice::RelayDeviceSync).
class Voice::VoipPushConfig
  APNS_ENVIRONMENTS = %w[development production].freeze

  CREDENTIALS = {
    apple: %w[APNS_VOIP_KEY APNS_VOIP_KEY_ID APNS_VOIP_TEAM_ID],
    android: %w[FIREBASE_PROJECT_ID FIREBASE_CREDENTIALS]
  }.freeze

  # report_partial: whether a platform with some but not all credentials set is reported
  def initialize(report_partial: true)
    @report_partial = report_partial
    @direct = {}
  end

  def configured?(platform) = direct?(platform) || relayed?(platform)

  # Every credential set. Some but not all set is a broken deployment rather than an opted-out
  # one, so it is reported; the relay, when on, still carries the platform.
  def direct?(platform)
    return @direct[platform] if @direct.key?(platform)

    names = CREDENTIALS.fetch(platform)
    missing = names.select { |name| config(name).blank? }
    if @report_partial && missing.any? && missing.size < names.size
      ChatwootExceptionTracker.new(ArgumentError.new("#{platform} push is partly configured; missing #{missing.join(', ')}")).capture_exception
    end
    @direct[platform] = missing.empty?
  end

  def relayed?(platform)
    !direct?(platform) && relay_enabled? && ChatwootHub.voice_relay_secret.present?
  end

  def relay_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PUSH_RELAY_SERVER', true))
  end

  # A misspelt environment would quietly send App Store tokens to the sandbox, so it raises
  def apple_environment
    environment = config('APNS_VOIP_ENVIRONMENT', 'production')
    return environment if APNS_ENVIRONMENTS.include?(environment)

    raise ArgumentError, "APNS_VOIP_ENVIRONMENT must be one of #{APNS_ENVIRONMENTS.join(', ')}, got #{environment.inspect}"
  end

  # The iPhone sender, with everything it needs read from the configuration, so its delivery
  # makes HTTP requests only
  def apple_sender(call_id:, expiry_seconds:)
    return Voice::HubRelaySender.new(platform: 'apple', call_id: call_id, expiry_seconds: expiry_seconds) unless direct?(:apple)

    Voice::ApnsVoipSender.new(settings: apple_settings(expiry_seconds), call_id: call_id)
  end

  # A callable that returns the Android sender. Configuration is read now; Firebase's own client
  # requests an access token from Google when it is made, so the callable runs on the delivery
  # thread.
  def android_sender_builder(call_id:, expiry_seconds:)
    return -> { Voice::HubRelaySender.new(platform: 'android', call_id: call_id, expiry_seconds: expiry_seconds) } unless direct?(:android)

    project_id = config('FIREBASE_PROJECT_ID')
    credentials = config('FIREBASE_CREDENTIALS')
    lambda do
      Voice::FcmVoipSender.new(client: Notification::FcmService.new(project_id, credentials).fcm_client, call_id: call_id,
                               expiry_seconds: expiry_seconds)
    end
  end

  private

  def apple_settings(expiry_seconds)
    {
      production: apple_environment == 'production',
      key: config('APNS_VOIP_KEY'),
      key_id: config('APNS_VOIP_KEY_ID'),
      team_id: config('APNS_VOIP_TEAM_ID'),
      # A cleared bundle ID falls back to the app's, as an unset one does
      topic: "#{config('APNS_VOIP_BUNDLE_ID').presence || 'com.chatwoot.app'}.voip",
      expiry_seconds: expiry_seconds
    }
  end

  def config(name, default = nil)
    GlobalConfigService.load(name, default)
  end
end
