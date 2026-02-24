module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_content
    return super unless Current.executed_by.instance_of?(Captain::Assistant)

    locale = Current.executed_by.account.locale
    key = captain_activity_key
    return unless key

    I18n.t(key, user_name: Current.executed_by.name, reason: Current.captain_resolve_reason, locale: locale)
  end

  private

  def captain_activity_key
    if resolved? && Current.captain_resolve_reason.present?
      'conversations.activity.captain.resolved_by_tool'
    elsif resolved?
      'conversations.activity.captain.resolved'
    elsif open?
      'conversations.activity.captain.open'
    end
  end
end
