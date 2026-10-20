module Enterprise::Conversations::EventDataPresenter
  def push_data
    data = super.merge(anonymous_caller: contact_inbox.anonymous_caller?)
    return data unless account.feature_enabled?('sla')

    sla_applicable = sla_applicable?

    data.merge(
      applied_sla: sla_applicable ? applied_sla&.push_event_data : nil,
      sla_events: sla_applicable ? sla_events.map(&:push_event_data) : [],
      sla_policy_id: sla_applicable ? sla_policy_id : nil
    )
  end
end
