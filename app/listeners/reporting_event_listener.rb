class ReportingEventListener < BaseListener
  include ReportingEventHelper

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]

    ReportingEvent.create!(
      name: 'conversation_created',
      value: 0,
      event_start_time: conversation.created_at,
      event_end_time: conversation.created_at,
      **base_event_attributes(conversation, from_state: nil)
    )
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    time_to_resolve = conversation.updated_at.to_i - conversation.created_at.to_i

    reporting_event = ReportingEvent.new(
      name: 'conversation_resolved',
      value: time_to_resolve,
      value_in_business_hours: business_hours(conversation.inbox, conversation.created_at, conversation.updated_at),
      event_start_time: conversation.created_at,
      event_end_time: conversation.updated_at,
      **base_event_attributes(conversation, from_state: 'handling')
    )

    create_bot_resolved_event(conversation, reporting_event)
    reporting_event.save!
  end

  def first_reply_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation
    first_response_time = message.created_at.to_i - last_non_human_activity(conversation).to_i

    ReportingEvent.create!(
      name: 'first_response',
      value: first_response_time,
      value_in_business_hours: business_hours(conversation.inbox, last_non_human_activity(conversation), message.created_at),
      event_start_time: last_non_human_activity(conversation),
      event_end_time: message.created_at,
      **base_event_attributes(conversation, from_state: 'waiting', user_id: message.sender_id)
    )
  end

  def reply_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation
    waiting_since = event.data[:waiting_since]

    return if waiting_since.blank?

    reply_time = message.created_at.to_i - waiting_since.to_i

    ReportingEvent.create!(
      name: 'reply_time',
      value: reply_time,
      value_in_business_hours: business_hours(conversation.inbox, waiting_since, message.created_at),
      event_start_time: waiting_since,
      event_end_time: message.created_at,
      **base_event_attributes(conversation, from_state: 'waiting')
    )
  end

  def conversation_bot_handoff(event)
    conversation = extract_conversation_and_account(event)[0]

    # check if a conversation_bot_handoff event exists for this conversation
    bot_handoff_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'conversation_bot_handoff')
    return if bot_handoff_event.present?

    time_to_handoff = conversation.updated_at.to_i - conversation.created_at.to_i

    ReportingEvent.create!(
      name: 'conversation_bot_handoff',
      value: time_to_handoff,
      value_in_business_hours: business_hours(conversation.inbox, conversation.created_at, conversation.updated_at),
      event_start_time: conversation.created_at,
      event_end_time: conversation.updated_at,
      **base_event_attributes(conversation, from_state: 'bot_handling')
    )
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]

    # Find the most recent resolved event for this conversation
    last_resolved_event = ReportingEvent.where(
      conversation_id: conversation.id,
      name: 'conversation_resolved'
    ).order(event_end_time: :desc).first

    # For first-time openings, value is 0, from_state is nil
    # For reopenings, calculate time since resolution, from_state is 'resolved'
    if last_resolved_event
      time_since_resolved = conversation.updated_at.to_i - last_resolved_event.event_end_time.to_i
      business_hours_value = business_hours(conversation.inbox, last_resolved_event.event_end_time, conversation.updated_at)
      start_time = last_resolved_event.event_end_time
      from_state = 'resolved'
    else
      time_since_resolved = 0
      business_hours_value = 0
      start_time = conversation.created_at
      from_state = nil
    end

    create_conversation_opened_event(conversation, time_since_resolved, business_hours_value, start_time, from_state)
  end

  private

  def base_event_attributes(conversation, from_state:, user_id: nil)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: user_id || conversation.assignee_id,
      conversation_id: conversation.id,
      conversation_created_at: conversation.created_at,
      team_id: conversation.team_id,
      channel_type: conversation.inbox.channel_type,
      from_state: from_state
    }
  end

  def create_conversation_opened_event(conversation, time_since_resolved, business_hours_value, start_time, from_state)
    ReportingEvent.create!(
      name: 'conversation_opened',
      value: time_since_resolved,
      value_in_business_hours: business_hours_value,
      event_start_time: start_time,
      event_end_time: conversation.updated_at,
      **base_event_attributes(conversation, from_state: from_state)
    )
  end

  def create_bot_resolved_event(conversation, reporting_event)
    return unless conversation.inbox.active_bot?
    # We don't want to create a bot_resolved event if there is user interaction on the conversation
    return if conversation.messages.exists?(message_type: :outgoing, sender_type: 'User')

    bot_resolved_event = reporting_event.dup
    bot_resolved_event.name = 'conversation_bot_resolved'
    bot_resolved_event.from_state = 'bot_handling'
    bot_resolved_event.save!
  end
end
