module Enterprise::Conversations::EventDataPresenter
  def push_data
    if account.feature_enabled?('sla')
      super.merge(
        applied_sla: applied_sla&.push_event_data,
        sla_events: sla_events.map(&:push_event_data)
      )
    else
      super
    end
  end
end
