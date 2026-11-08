class Voice::RingReadiness
  pattr_initialize [:user!]

  Platform = Struct.new(:problem, :devices, keyword_init: true) do
    def configured = problem.nil?
  end
  Membership = Struct.new(:account, :voice_enabled, :ringing_enabled, :voice_inboxes, :assigned_only_inboxes, :availability,
                          :accepts_calls, keyword_init: true)

  def apple
    @apple ||= Platform.new(problem: apple_problem, devices: user.notification_subscriptions.apns_voip.count)
  end

  def android
    @android ||= Platform.new(problem: credentials?(:android) ? nil : 'credentials', devices: android_devices)
  end

  def memberships
    @memberships ||= user.account_users.includes(:account).order(:account_id).map do |account_user|
      account = account_user.account
      reach = voice_inboxes(account).filter_map { |inbox| rung_for(inbox, account_user) }
      Membership.new(account: account, voice_enabled: account.feature_enabled?('channel_voice'),
                     ringing_enabled: account.feature_enabled?('mobile_voice_push'),
                     voice_inboxes: reach.size, assigned_only_inboxes: reach.count(:assigned),
                     availability: account_user.availability, accepts_calls: account_user.accepts_calls)
    end
  end

  def rings?(membership)
    blocker(membership).nil?
  end

  def blocker(membership)
    membership_blocker(membership) || device_blocker
  end

  def rings_assigned_only?(membership)
    rings?(membership) && membership.assigned_only_inboxes == membership.voice_inboxes
  end

  private

  def membership_blocker(membership)
    return 'voice_off' unless membership.voice_enabled
    return 'ringing_off' unless membership.ringing_enabled
    return 'no_inboxes' unless membership.voice_inboxes.positive?
    return 'not_online' unless membership.availability == 'online'

    'calls_off' unless membership.accepts_calls
  end

  def device_blocker
    return 'no_device' unless registered_device?

    'push_unavailable' unless ringable_device?
  end

  def registered_device?
    apple.devices.positive? || android.devices.positive?
  end

  # An invalid APNs environment prevents delivery to both platforms.
  def ringable_device?
    return false if apple.problem == 'environment'

    [apple, android].any? { |platform| platform.configured && platform.devices.positive? }
  end

  def apple_problem
    return 'credentials' unless credentials?(:apple)

    environment = GlobalConfigService.load('APNS_VOIP_ENVIRONMENT', 'production')
    'environment' unless Voice::VoipPushService::APNS_ENVIRONMENTS.include?(environment)
  end

  def credentials?(platform)
    Voice::VoipPushService::CREDENTIALS.fetch(platform).all? { |name| GlobalConfigService.load(name, nil).present? }
  end

  # Returns :all, :assigned, or nil according to conversation visibility.
  def rung_for(inbox, account_user)
    return unless inbox.assignable_agents.include?(user)
    return :all if opens?(Conversation.new(account: account_user.account, inbox: inbox), account_user)

    :assigned if opens?(Conversation.new(account: account_user.account, inbox: inbox, assignee: user), account_user)
  end

  def opens?(conversation, account_user)
    ConversationPolicy.new({ user: user, account: account_user.account, account_user: account_user }, conversation).show?
  end

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
