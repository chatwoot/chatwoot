class ReportingEventListener < BaseListener
  include ReportingEventHelper

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    return if conversation.resolved_at.blank?

    service = resolution_service(conversation)
    last_opened_event = service.find_last_opened_event
    start_time = last_opened_event&.event_end_time || conversation.created_at
    end_time = conversation.resolved_at
    time_to_resolve = end_time - start_time
    return if time_to_resolve <= 0

    service.create_conversation_resolved_events(start_time, end_time, time_to_resolve)

    if conversation.inbox.active_bot?
      bot_svc = bot_service(conversation)
      without_bot_start_time = bot_svc.bot_handoff_time || first_operator_assigned_at(conversation)
      return if without_bot_start_time.nil?
    else
      without_bot_start_time = start_time
    end

    service.create_resolution_without_bot_events(without_bot_start_time)
  end

  def first_reply_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation

    return unless outgoing_user_message?(message)

    participant = find_active_participant(conversation, message.sender_id)
    return if participant.blank? || participant.created_at.blank?

    service = response_service(conversation, message, participant)
    service.create_first_response_event
    service.create_first_response_from_open_event
  end

  def reply_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.sender_type == 'User'

    conversation = message.conversation
    operator_id = message.sender_id

    participant = find_active_participant(conversation, operator_id)
    return if participant&.created_at.blank?

    service = response_service(conversation, message, participant)
    client_message = service.last_client_message_for_operator
    return unless client_message

    waiting_time = message.created_at.to_i - client_message.created_at.to_i
    return if waiting_time <= 0

    service.create_reply_time_event(operator_id, client_message, waiting_time)
  end

  def conversation_bot_handoff(event)
    conversation = extract_conversation_and_account(event)[0]

    service = bot_service(conversation)
    return if service.bot_handoff_event_exists?

    time_to_handoff = conversation.updated_at.to_i - conversation.created_at.to_i
    service.create_bot_handoff_event(time_to_handoff)
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    service = resolution_service(conversation)
    last_resolved_event = service.find_last_resolved_event

    if last_resolved_event
      time_since_resolved = conversation.updated_at.to_i - last_resolved_event.event_end_time.to_i
      business_hours_value = business_hours(conversation.inbox, last_resolved_event.event_end_time, conversation.updated_at)
      start_time = last_resolved_event.event_end_time
    else
      time_since_resolved = 0
      business_hours_value = 0
      start_time = conversation.created_at
    end

    service.create_conversation_opened_event(time_since_resolved, business_hours_value, start_time)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation

    service = bot_service(conversation, message)
    return unless service.bot_message_applicable?

    service.handle_bot_first_response if service.bot_first_response_applicable?
    service.handle_bot_reply_time
  end

  private

  def first_operator_assigned_at(conversation)
    bot_svc = bot_service(conversation)
    handoff_time = bot_svc.bot_handoff_time

    after_time = handoff_time || last_bot_message_time(conversation)

    return nil if after_time.nil?

    ConversationParticipant
      .where(conversation_id: conversation.id)
      .where.not(user_id: nil)
      .where('created_at >= ?', after_time)
      .order(created_at: :asc)
      .first&.created_at
  end

  def last_bot_message_time(conversation)
    conversation.messages
                .where(message_type: :outgoing, sender_type: ['AgentBot', 'Captain::Assistant'])
                .order(created_at: :desc)
                .first&.created_at
  end

  def bot_handoff_time
    ReportingEvent.where(
      conversation_id: conversation.id,
      name: 'bot_handoff'
    ).order(created_at: :asc).first&.event_end_time
  end

  def find_active_participant(conversation, user_id)
    ConversationParticipant.find_by(
      conversation_id: conversation.id,
      user_id: user_id,
      left_at: nil
    )
  end

  def outgoing_user_message?(message)
    message.message_type == 'outgoing' && message.sender_type == 'User'
  end

  def bot_service(conversation, message = nil)
    ReportingEvents::BotEventService.new(conversation, message)
  end

  def response_service(conversation, message, participant = nil)
    ReportingEvents::ResponseEventService.new(conversation, message, participant)
  end

  def resolution_service(conversation)
    ReportingEvents::ResolutionEventService.new(conversation)
  end
end
