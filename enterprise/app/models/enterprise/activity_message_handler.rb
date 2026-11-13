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

  def create_activity
    super
    handle_auto_translate_change(determine_user_name)
  end

  def handle_auto_translate_change(user_name)
    return unless user_name && saved_change_to_additional_attributes?

    before, after = previous_changes['additional_attributes']
    # nil (never set) and false both mean auto-translate is on, so nil -> false is not a change
    was_disabled = (before || {})['auto_translate_disabled'] == true
    now_disabled = (after || {})['auto_translate_disabled'] == true
    return if was_disabled == now_disabled

    change_type = now_disabled ? 'disabled' : 'enabled'
    content = I18n.t("conversations.activity.auto_translate.#{change_type}", user_name: user_name)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content))
  end

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
