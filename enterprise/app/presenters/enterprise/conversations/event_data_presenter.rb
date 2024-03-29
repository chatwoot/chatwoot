module Enterprise::Conversations::EventDataPresenter
  def push_data
    super.merge(
      applied_sla: applied_sla&.push_event_data,
      sla_events: sla_events.map(&:push_event_data)
    )
  end
end
