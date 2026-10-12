module SuperAdmin::UserDiagnosticsHelper
  # Order used by the agent notification preferences screen. Differs from the enum order.
  # Labels: super_admin.user_diagnostics.push_types.
  PUSH_TYPE_ORDER = %i[
    conversation_creation
    conversation_assignment
    conversation_mention
    assigned_conversation_new_message
    participating_conversation_new_message
    sla_missed_first_response
    sla_missed_next_response
    sla_missed_resolution
  ].freeze
  PUSH_NOTIFICATION_TYPES = (PUSH_TYPE_ORDER + Notification::NOTIFICATION_TYPES.keys).uniq.freeze
  # Available only on accounts with the SLA feature.
  SLA_PUSH_TYPES = %i[sla_missed_first_response sla_missed_next_response sla_missed_resolution].freeze
  # Subscription attributes rendered on the page. Excludes push_token, device_id and web push keys.
  DEVICE_DETAIL_KEYS = %w[devicePlatform deviceName brandName apiLevel buildNumber].freeze

  # SLA types are included only when an account has the feature.
  def push_types(settings)
    return PUSH_NOTIFICATION_TYPES if settings.any? { |setting| sla_enabled?(setting) }

    PUSH_NOTIFICATION_TYPES - SLA_PUSH_TYPES
  end

  # Returns :on, :off, or :unavailable.
  def push_state(setting, type)
    return :unavailable if SLA_PUSH_TYPES.include?(type) && !sla_enabled?(setting)

    setting.public_send("push_#{type}?") ? :on : :off
  end

  def any_push_enabled?(setting, types)
    types.any? { |type| push_state(setting, type) == :on }
  end

  def sla_enabled?(setting)
    setting.account&.feature_enabled?('sla')
  end

  def push_type_label(type)
    t("super_admin.user_diagnostics.push_types.#{type}", default: type.to_s.humanize)
  end

  def account_label(setting)
    setting.account&.name || t('super_admin.user_diagnostics.push_settings.unnamed_account', id: setting.account_id)
  end

  def device_details(subscription)
    subscription_attrs(subscription).slice(*DEVICE_DETAIL_KEYS)
  end

  # Web push reports the service worker host, FCM the tail of the device identifier.
  def device_identifier(subscription)
    attrs = subscription_attrs(subscription)
    return truncated_tail(attrs['device_id']) unless subscription.browser_push?

    endpoint = attrs['endpoint'].to_s
    host = begin
      URI.parse(endpoint).host
    rescue URI::InvalidURIError
      nil
    end
    host.presence || endpoint.presence
  end

  # Enough to correlate a row with a provider log, too little to send with.
  def device_token_tail(subscription)
    attrs = subscription_attrs(subscription)
    truncated_tail(subscription.browser_push? ? attrs['endpoint'] : attrs['push_token'])
  end

  private

  def subscription_attrs(subscription)
    subscription.subscription_attributes.to_h.stringify_keys
  end

  def truncated_tail(value)
    return if value.blank?

    "…#{value.to_s.last(6)}"
  end
end
