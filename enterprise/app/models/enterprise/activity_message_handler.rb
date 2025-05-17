module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_content
    if Current.executed_by.instance_of?(Captain::Assistant)
      locale = Current.executed_by.account.locale
      message = if resolved?
                  'conversations.activity.captain.resolved'
                elsif open?
                  'conversations.activity.captain.open'
                end

      if message.present?
        I18n.t(
          message,
          user_name: Current.executed_by.name,
          locale: locale
        )
      end
    else
      super
    end
  end
end
