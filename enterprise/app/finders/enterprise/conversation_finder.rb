module Enterprise::ConversationFinder
  def conversations_base_query
    return super unless current_account.feature_enabled?('sla')

    super.includes(:applied_sla, :sla_events, inbox: :working_hours)
  end
end
