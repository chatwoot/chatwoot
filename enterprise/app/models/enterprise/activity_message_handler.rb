module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_content
    return super unless Current.executed_by.instance_of?(Captain::Assistant)
    return unless resolved? || open?

    locale = Current.executed_by.account.locale
    user_name = Current.executed_by.name
    key = captain_activity_key

    I18n.t(key, user_name: user_name, locale: locale)
  end

  private

  def captain_activity_key
    return 'conversations.activity.captain.open' if open?
    return 'conversations.activity.captain.tool_resolved' if Current.tool_name == 'resolve'

    'conversations.activity.captain.resolved'
  end
end
