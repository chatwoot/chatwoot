class ReportingEventListener < BaseListener
  include ReportingEventHelper

  def conversation_resolved(event) # rubocop:disable Metrics/AbcSize
    conversation = extract_conversation_and_account(event)[0]
    performed_by = extract_performed_by(event)

    time_to_resolve = conversation.updated_at.to_i - last_agent_assignment(conversation).to_i

    return if conversation.account_id == 560 && (conversation.assignee_id == 1519 || conversation.assignee_id == 1520)

    reporting_event = ReportingEvent.new(
      name: 'conversation_resolved',
      value: time_to_resolve,
      value_in_business_hours: business_hours(conversation.inbox, last_agent_assignment(conversation),
                                              conversation.updated_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id || (performed_by.id if performed_by.present?),
      conversation_id: conversation.id,
      event_start_time: last_agent_assignment(conversation),
      event_end_time: conversation.updated_at
    )

    create_bot_resolved_event(conversation, reporting_event)
    reporting_event.save!
  end

  def first_reply_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation

    return if conversation.resolved?
    return if conversation.account_id == 560 && (message.sender_id == 1519 || message.sender_id == 1520)

    first_response_time = message.created_at.to_i - last_agent_assignment(conversation).to_i

    reporting_event = ReportingEvent.new(
      name: 'first_response',
      value: first_response_time,
      value_in_business_hours: business_hours(conversation.inbox, last_agent_assignment(conversation),
                                              message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: message.sender_id,
      conversation_id: conversation.id,
      event_start_time: last_agent_assignment(conversation),
      event_end_time: message.created_at
    )

    reporting_event.save!
  end

  def reply_created(event) # rubocop:disable Metrics/AbcSize
    message = extract_message_and_account(event)[0]
    conversation = message.conversation

    return if conversation.resolved?
    return if conversation.account_id == 560 && (conversation.assignee_id == 1519 || conversation.assignee_id == 1520)

    waiting_since = event.data[:waiting_since]

    return if waiting_since.blank?

    # When waiting_since is nil, set reply_time to 0
    reply_time = message.created_at.to_i - waiting_since.to_i

    reporting_event = ReportingEvent.new(
      name: 'reply_time',
      value: reply_time,
      value_in_business_hours: business_hours(conversation.inbox, waiting_since, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id || message.sender_id,
      conversation_id: conversation.id,
      event_start_time: waiting_since,
      event_end_time: message.created_at
    )
    reporting_event.save!
  end

  def conversation_bot_handoff(event)
    conversation = extract_conversation_and_account(event)[0]

    # check if a conversation_bot_handoff event exists for this conversation
    bot_handoff_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'conversation_bot_handoff')
    return if bot_handoff_event.present?

    time_to_handoff = conversation.updated_at.to_i - conversation.created_at.to_i

    reporting_event = ReportingEvent.new(
      name: 'conversation_bot_handoff',
      value: time_to_handoff,
      value_in_business_hours: business_hours(conversation.inbox, conversation.created_at, conversation.updated_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: conversation.created_at,
      event_end_time: conversation.updated_at
    )
    reporting_event.save!
  end

  def conversation_first_call(event)
    conversation = extract_conversation_and_account(event)[0]
    return if conversation.account_id == 560 && (conversation.assignee_id == 1519 || conversation.assignee_id == 1520)

    reporting_event = ReportingEvent.new(
      name: 'conversation_first_call',
      value: conversation.updated_at.to_i - conversation.nudge_created.to_i,
      value_in_business_hours: business_hours(conversation.inbox, conversation.nudge_created, conversation.updated_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: conversation.nudge_created,
      event_end_time: conversation.updated_at
    )
    reporting_event.save!
  end

  def conversation_call_converted(event) # rubocop:disable Metrics/AbcSize
    conversation = extract_conversation_and_account(event)[0]
    performed_by = extract_performed_by(event)

    return if conversation.account_id == 560 && (conversation.assignee_id == 1519 || conversation.assignee_id == 1520)

    reporting_event = ReportingEvent.new(
      name: 'conversation_call_converted',
      value: conversation.updated_at.to_i - conversation.nudge_created.to_i,
      value_in_business_hours: business_hours(conversation.inbox, conversation.nudge_created, conversation.updated_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id || (performed_by.id if performed_by.present?),
      conversation_id: conversation.id,
      event_start_time: conversation.nudge_created,
      event_end_time: conversation.updated_at
    )
    reporting_event.save!
  end

  def conversation_call_dropped(event) # rubocop:disable Metrics/AbcSize
    conversation = extract_conversation_and_account(event)[0]
    performed_by = extract_performed_by(event)

    return if conversation.account_id == 560 && (conversation.assignee_id == 1519 || conversation.assignee_id == 1520)

    reporting_event = ReportingEvent.new(
      name: 'conversation_call_dropped',
      value: conversation.updated_at.to_i - conversation.nudge_created.to_i,
      value_in_business_hours: business_hours(conversation.inbox, conversation.nudge_created, conversation.updated_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id || (performed_by.id if performed_by.present?),
      conversation_id: conversation.id,
      event_start_time: conversation.nudge_created,
      event_end_time: conversation.updated_at
    )
    reporting_event.save!
  end

  private

  def create_bot_resolved_event(conversation, reporting_event)
    return unless conversation.inbox.active_bot?
    # We don't want to create a bot_resolved event if there is user interaction on the conversation
    return if conversation.messages.exists?(message_type: :outgoing, sender_type: 'User')

    bot_resolved_event = reporting_event.dup
    bot_resolved_event.name = 'conversation_bot_resolved'
    bot_resolved_event.save!
  end
end
