module Enterprise::ConversationFinder
  def conversations_base_query
    current_account.feature_enabled?('sla') ? super.includes(:applied_sla, :sla_events) : super
  end
end
