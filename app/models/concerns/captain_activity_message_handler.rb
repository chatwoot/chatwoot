module CaptainActivityMessageHandler
  extend ActiveSupport::Concern

  included do
    attr_accessor :captain_activity_reason, :captain_activity_reason_type
  end

  # Attributes the status-change activity message while Captain performs the
  # transition, so activity notes can say why Captain resolved or reopened.
  def with_captain_activity_context(reason:, reason_type:)
    previous_reason = captain_activity_reason
    previous_reason_type = captain_activity_reason_type

    self.captain_activity_reason = reason
    self.captain_activity_reason_type = reason_type
    yield
  ensure
    self.captain_activity_reason = previous_reason
    self.captain_activity_reason_type = previous_reason_type
  end

  private

  def captain_status_change_activity_content
    I18n.t(
      captain_activity_key,
      user_name: Current.executed_by.name,
      reason: captain_activity_reason.presence,
      locale: Current.executed_by.account.locale
    )
  end

  def captain_activity_key
    return captain_resolved_activity_key if resolved?
    return captain_open_activity_key if open?
  end

  def captain_resolved_activity_key
    if captain_activity_reason_type == :tool && captain_activity_reason.present?
      return 'conversations.activity.captain.resolved_by_tool'
    end

    return 'conversations.activity.captain.resolved_with_reason' if captain_activity_reason.present?

    'conversations.activity.captain.resolved'
  end

  def captain_open_activity_key
    return 'conversations.activity.captain.open_with_reason' if captain_activity_reason.present?

    'conversations.activity.captain.open'
  end
end
