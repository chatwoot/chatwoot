module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_content
    return user_status_change_activity_content(Current.user.name) if Current.executed_by.instance_of?(CopilotRun::Action)
    return super unless Current.executed_by.instance_of?(Captain::Assistant)

    locale = Current.executed_by.account.locale
    key = captain_activity_key
    return unless key

    I18n.t(key, user_name: Current.executed_by.name, reason: captain_status_reason, locale: locale)
  end

  private

  # Every activity message is built here, whichever concern creates it, so this one override covers them all.
  def activity_message_params(content, content_attributes: nil)
    return super unless Current.executed_by.instance_of?(CopilotRun::Action)

    super(I18n.t('conversations.activity.via_copilot', activity: content), content_attributes: content_attributes)
  end

  def captain_status_reason
    captain_activity_reason.presence
  end

  def captain_activity_key
    return captain_resolved_activity_key if resolved?
    return captain_open_activity_key if open?
  end

  def captain_resolved_activity_key
    return 'conversations.activity.captain.resolved_by_tool' if captain_activity_reason_type == :tool && captain_status_reason.present?
    return 'conversations.activity.captain.resolved_with_reason' if captain_status_reason.present?

    'conversations.activity.captain.resolved'
  end

  def captain_open_activity_key
    return 'conversations.activity.captain.open_with_reason' if captain_status_reason.present?

    'conversations.activity.captain.open'
  end
end
