module Voice::VoipPushConfiguration
  RING_EXPIRY_SECONDS = 45

  APNS_ENVIRONMENTS = %w[development production].freeze

  CREDENTIALS = {
    apple: %w[APNS_VOIP_KEY APNS_VOIP_KEY_ID APNS_VOIP_TEAM_ID],
    android: %w[FIREBASE_PROJECT_ID FIREBASE_CREDENTIALS]
  }.freeze

  private

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

  def apple_environment
    environment = config('APNS_VOIP_ENVIRONMENT', 'production')
    return environment if APNS_ENVIRONMENTS.include?(environment)

    raise ArgumentError, "APNS_VOIP_ENVIRONMENT must be one of #{APNS_ENVIRONMENTS.join(', ')}, got #{environment.inspect}"
  end

  def apple_settings
    {
      production: apple_environment == 'production',
      key: config('APNS_VOIP_KEY'),
      key_id: config('APNS_VOIP_KEY_ID'),
      team_id: config('APNS_VOIP_TEAM_ID'),
      topic: "#{config('APNS_VOIP_BUNDLE_ID').presence || 'com.chatwoot.app'}.voip",
      expiry_seconds: RING_EXPIRY_SECONDS
    }
  end

  def firebase_config
    [config('FIREBASE_PROJECT_ID'), config('FIREBASE_CREDENTIALS')]
  end

  def config(name, default = nil)
    GlobalConfigService.load(name, default)
  end
end
