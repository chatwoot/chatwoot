module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_content
    if Current.executed_by.instance_of?(Captain::Assistant) && resolved?
      I18n.t('conversations.activity.captain.resolved', user_name: Current.executed_by.name)
    else
      super
    end
  end
end
