module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_content
    return super unless Current.executed_by.instance_of?(Captain::Assistant)

    locale = Current.executed_by.account.locale
    key = captain_activity_key
    return unless key

    I18n.t(key, user_name: Current.executed_by.name, reason: captain_activity_reason, locale: locale)
  end

  private

  def captain_activity_reason
    Current.captain_activity_reason.presence || Current.captain_resolve_reason
  end

  def captain_activity_key
    return captain_resolved_activity_key if resolved?
    return captain_open_activity_key if open?
  end

  def captain_resolved_activity_key
    return 'conversations.activity.captain.resolved_by_tool' if Current.captain_resolve_reason.present?
    return 'conversations.activity.captain.resolved_with_reason' if Current.captain_activity_reason.present?

    'conversations.activity.captain.resolved'
  end

  def captain_open_activity_key
    return 'conversations.activity.captain.open_with_reason' if Current.captain_activity_reason.present?

    'conversations.activity.captain.open'
  end
end
