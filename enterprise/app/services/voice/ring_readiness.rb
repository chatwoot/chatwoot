# Whether a call rings an agent's phones while the app is in the background or closed: the
# installation's push settings, the devices the app registered for rings, and on each
# account the call features, the voice inboxes the agent is rung for, and their status.
# Shown in the Super Admin diagnostics.
class Voice::RingReadiness
  pattr_initialize [:user!]

  # problem: nil when the platform can be pushed to, otherwise 'credentials' or 'environment'
  Platform = Struct.new(:problem, :devices, keyword_init: true) do
    def configured = problem.nil?
  end
  Membership = Struct.new(:account, :voice_enabled, :ringing_enabled, :voice_inboxes, :availability, keyword_init: true)

  def apple
    @apple ||= Platform.new(problem: apple_problem, devices: user.notification_subscriptions.apns_voip.count)
  end

  def android
    @android ||= Platform.new(problem: credentials?(:android) ? nil : 'credentials', devices: android_devices)
  end

  def memberships
    @memberships ||= user.account_users.includes(:account).order(:account_id).map do |account_user|
      account = account_user.account
      Membership.new(account: account, voice_enabled: account.feature_enabled?('channel_voice'),
                     ringing_enabled: account.feature_enabled?('mobile_voice_push'),
                     voice_inboxes: voice_inboxes(account).count { |inbox| inbox.assignable_agents.include?(user) },
                     availability: account_user.availability)
    end
  end

  # A call rings the agents its inbox can be assigned to, when they are online, on
  # accounts with both features, on a platform the installation can push to
  def rings?(membership)
    membership.voice_enabled && membership.ringing_enabled && membership.voice_inboxes.positive? &&
      membership.availability == 'online' && ringable_device?
  end

  private

  def ringable_device?
    [apple, android].any? { |platform| platform.configured && platform.devices.positive? }
  end

  # The checks the push itself makes: every credential set, and an environment it accepts
  def apple_problem
    return 'credentials' unless credentials?(:apple)

    environment = GlobalConfigService.load('APNS_VOIP_ENVIRONMENT', 'production')
    'environment' unless Voice::VoipPushService::APNS_ENVIRONMENTS.include?(environment)
  end

  def credentials?(platform)
    Voice::VoipPushService::CREDENTIALS.fetch(platform).all? { |name| GlobalConfigService.load(name, nil).present? }
  end

  # The inboxes that take incoming calls
  def voice_inboxes(account)
    account.inboxes.includes(:channel).select do |inbox|
      channel = inbox.channel
      channel.respond_to?(:voice_enabled?) && channel.voice_enabled? && channel.inbound_calls_enabled?
    end
  end

  def android_devices
    user.notification_subscriptions.fcm.count do |subscription|
      subscription.subscription_attributes['devicePlatform'].to_s.casecmp('android').zero?
    end
  end
end
