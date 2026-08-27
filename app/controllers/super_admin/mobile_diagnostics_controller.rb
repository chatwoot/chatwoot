class SuperAdmin::MobileDiagnosticsController < SuperAdmin::ApplicationController
  # X-Chatwoot-Client-Name value sent by the mobile app.
  MOBILE_CLIENT_NAME = 'Chatwoot Mobile'.freeze
  # Order used by the agent notification preferences screen. Differs from the enum order.
  # Labels: super_admin.mobile_diagnostics.push_types.
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
  # Subscription attributes rendered on the page. Excludes push_token and device_id.
  DEVICE_DETAIL_KEYS = %w[devicePlatform deviceName brandName apiLevel buildNumber].freeze
  # Available only on accounts with the SLA feature.
  SLA_PUSH_TYPES = %i[sla_missed_first_response sla_missed_next_response sla_missed_resolution].freeze

  before_action :ensure_available
  helper_method :push_state, :push_type_label, :device_details, :duplicate_device?

  def show
    @query = params[:user_query].to_s.strip
    @user = resolve_user(@query)
    @mobile_sessions, web_sessions = sessions_for_user.partition { |session| mobile?(session) }
    @web_session_count = web_sessions.size
    @device_subscriptions = @user ? @user.notification_subscriptions.fcm.order(:id) : []
    @duplicate_device_ids = duplicate_device_ids
    @notification_settings = @user ? @user.notification_settings.includes(:account).order(:account_id) : []
    @push_types = push_types
    @accounts_without_push = @notification_settings.select { |setting| all_push_off?(setting) }
  end

  # Returns :on, :off, or :unavailable.
  def push_state(setting, type)
    return :unavailable if SLA_PUSH_TYPES.include?(type) && !sla_enabled?(setting)

    setting.public_send("push_#{type}?") ? :on : :off
  end

  def push_type_label(type)
    I18n.t("super_admin.mobile_diagnostics.push_types.#{type}", default: type.to_s.humanize)
  end

  def device_details(subscription)
    subscription.subscription_attributes.to_h.stringify_keys.slice(*DEVICE_DETAIL_KEYS)
  end

  def duplicate_device?(subscription)
    device_id = device_id_for(subscription)
    device_id.present? && @duplicate_device_ids.include?(device_id)
  end

  private

  def ensure_available
    return if ChatwootApp.chatwoot_cloud?

    redirect_to super_admin_root_path, alert: I18n.t('super_admin.mobile_diagnostics.unavailable')
  end

  # SLA types are included only when an account has the feature.
  def push_types
    return PUSH_NOTIFICATION_TYPES if @notification_settings.any? { |setting| sla_enabled?(setting) }

    PUSH_NOTIFICATION_TYPES - SLA_PUSH_TYPES
  end

  def all_push_off?(setting)
    @push_types.none? { |type| push_state(setting, type) == :on }
  end

  def sla_enabled?(setting)
    setting.account&.feature_enabled?('sla')
  end

  def sessions_for_user
    return [] if @user.nil?

    @user.user_sessions.order(Arel.sql('COALESCE(last_activity_at, created_at) DESC'))
  end

  # Device ids holding more than one active subscription.
  def duplicate_device_ids
    @device_subscriptions
      .group_by { |subscription| device_id_for(subscription) }
      .select { |device_id, subscriptions| device_id.present? && subscriptions.size > 1 }
      .keys
  end

  def device_id_for(subscription)
    subscription.subscription_attributes.to_h.stringify_keys['device_id'].presence
  end

  def mobile?(session)
    session.browser_name == MOBILE_CLIENT_NAME
  end

  def resolve_user(query)
    return if query.blank?

    query.match?(/\A\d+\z/) ? User.find_by(id: query) : User.from_email(query)
  end
end
