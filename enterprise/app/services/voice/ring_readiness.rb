# Whether a call rings an agent's phones while the app is in the background or closed: the
# installation's push credentials, the devices the app registered for rings, and on each
# account the call features and the agent's status. Shown in the Super Admin diagnostics.
class Voice::RingReadiness
  pattr_initialize [:user!]

  Platform = Struct.new(:configured, :devices, keyword_init: true)
  Membership = Struct.new(:account, :voice_enabled, :ringing_enabled, :availability, keyword_init: true)

  def apple
    @apple ||= Platform.new(configured: configured?(:apple), devices: user.notification_subscriptions.apns_voip.count)
  end

  def android
    @android ||= Platform.new(configured: configured?(:android), devices: android_devices)
  end

  def memberships
    @memberships ||= user.account_users.includes(:account).order(:account_id).map do |account_user|
      account = account_user.account
      Membership.new(account: account, voice_enabled: account.feature_enabled?('channel_voice'),
                     ringing_enabled: account.feature_enabled?('mobile_voice_push'), availability: account_user.availability)
    end
  end

  # Rings go to online agents on accounts with both features, on a platform the
  # installation can push to
  def rings?(membership)
    membership.voice_enabled && membership.ringing_enabled && membership.availability == 'online' && ringable_device?
  end

  private

  def ringable_device?
    [apple, android].any? { |platform| platform.configured && platform.devices.positive? }
  end

  def configured?(platform)
    Voice::VoipPushService::CREDENTIALS.fetch(platform).all? { |name| GlobalConfigService.load(name, nil).present? }
  end

  def android_devices
    user.notification_subscriptions.fcm.count do |subscription|
      subscription.subscription_attributes['devicePlatform'].to_s.casecmp('android').zero?
    end
  end
end
