module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_params
    return super unless Current.executed_by.instance_of?(Captain::Assistant)

    key = captain_activity_key
    return unless key

    I18n.with_locale(Current.executed_by.account.locale) do
      activity_message_params(
        key,
        content_attributes: { activity: { type: 'conversation_status_changed', status: status } },
        user_name: Current.executed_by.name, reason: captain_status_reason
      )
    end
  end

  private

  def captain_status_reason
    captain_activity_reason.presence
  end

  def captain_activity_key
    return captain_resolved_activity_key if resolved?
    return captain_open_activity_key if open?
  end

  def captain_resolved_activity_key
    return 'captain.resolved_by_tool' if captain_activity_reason_type == :tool && captain_status_reason.present?
    return 'captain.resolved_with_reason' if captain_status_reason.present?

    'captain.resolved'
  end

  def captain_open_activity_key
    return 'captain.open_with_reason' if captain_status_reason.present?

    'captain.open'
  end
end
