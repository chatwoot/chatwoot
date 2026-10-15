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
  # voice_inboxes: inboxes whose calls ring the agent; assigned_only_inboxes: of those, the ones
  # where their role limits it to calls already assigned to them
  Membership = Struct.new(:account, :voice_enabled, :ringing_enabled, :voice_inboxes, :assigned_only_inboxes, :availability,
                          keyword_init: true)

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
                     availability: account_user.availability)
    end
  end

  # A call rings the agents its inbox can be assigned to, when they are online, on
  # accounts with both features, on a platform the installation can push to
  def rings?(membership)
    blocker(membership).nil?
  end

  # The first reason a call does not ring the agent's phone on the account, nil when it rings:
  # 'voice_off', 'ringing_off', 'no_inboxes', 'not_online', 'no_device' or 'push_unavailable'
  def blocker(membership)
    return 'voice_off' unless membership.voice_enabled
    return 'ringing_off' unless membership.ringing_enabled
    return 'no_inboxes' unless membership.voice_inboxes.positive?
    return 'not_online' unless membership.availability == 'online'
    return 'no_device' unless registered_device?

    'push_unavailable' unless ringable_device?
  end

  # Rings, but only for calls in conversations already assigned to the agent
  def rings_assigned_only?(membership)
    rings?(membership) && membership.assigned_only_inboxes == membership.voice_inboxes
  end

  private

  def registered_device?
    apple.devices.positive? || android.devices.positive?
  end

  # An APNs environment the push rejects stops the ring before either platform is sent to
  def ringable_device?
    return false if apple.problem == 'environment'

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

  # Which calls in the inbox ring the agent, as Voice::RingRecipients decides for a real call:
  # :all when their role lets them open an unassigned call's conversation, :assigned when it
  # only lets them open conversations assigned to them, nil when none ring them
  def rung_for(inbox, account_user)
    return unless inbox.assignable_agents.include?(user)
    return :all if opens?(Conversation.new(account: account_user.account, inbox: inbox), account_user)

    :assigned if opens?(Conversation.new(account: account_user.account, inbox: inbox, assignee: user), account_user)
  end

  def opens?(conversation, account_user)
    ConversationPolicy.new({ user: user, account: account_user.account, account_user: account_user }, conversation).show?
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
