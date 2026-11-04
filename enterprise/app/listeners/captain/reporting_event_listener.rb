class Captain::ReportingEventListener < BaseListener
  def captain_conversation_handed_off(event)
    create_captain_inference_event(event, 'conversation_captain_inference_handoff') if event.data[:source] == 'inference'
  end

  def captain_conversation_resolved(event)
    create_captain_inference_event(event, 'conversation_captain_inference_resolved') if event.data[:source] == 'inference'
  end

  private

  def create_captain_inference_event(event, event_name)
    conversation = extract_conversation_and_account(event)[0]
    time_to_event = event.timestamp.to_i - conversation.created_at.to_i

    ReportingEvent.create!(
      name: event_name,
      value: time_to_event,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: conversation.created_at,
      event_end_time: event.timestamp
    )
  end
end
