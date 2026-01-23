class ReportingEventListener < BaseListener
  include ReportingEventHelper

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    return if conversation.resolved_at.blank?

    first_incoming_message = conversation.messages.incoming.order(:created_at).first
    start_time = first_incoming_message&.created_at || conversation.created_at

    end_time = conversation.resolved_at
    time_to_resolve = [end_time - start_time, 0].max

    create_conversation_resolved_events(conversation, start_time, end_time, time_to_resolve)
  end

  def first_reply_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation

    return unless first_reply_applicable?(message, conversation)

    participant = ConversationParticipant.find_by(conversation_id: conversation.id, user_id: message.sender_id, left_at: nil)
    return if participant.blank?
    return if participant.created_at.blank?

    assignment_time = participant.created_at
    first_response_time = message.created_at.to_i - assignment_time.to_i
    return if first_response_time <= 0

    create_first_response_event(conversation, message, assignment_time, first_response_time)
  end

  def reply_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.sender_type == 'User'

    conversation = message.conversation
    operator_id = message.sender_id

    participant = ConversationParticipant.find_by(conversation_id: conversation.id, user_id: operator_id, left_at: nil)
    return if participant&.created_at.blank?

    client_message = last_client_message(conversation, participant, message)
    return unless client_message

    waiting_time = message.created_at.to_i - client_message.created_at.to_i
    return if waiting_time <= 0

    create_reply_time_event(conversation, operator_id, client_message, message, waiting_time)
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

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]

    # Find the most recent resolved event for this conversation
    last_resolved_event = ReportingEvent.where(
      conversation_id: conversation.id,
      name: 'conversation_resolved'
    ).order(event_end_time: :desc).first

    # For first-time openings, value is 0
    # For reopenings, calculate time since resolution
    if last_resolved_event
      time_since_resolved = conversation.updated_at.to_i - last_resolved_event.event_end_time.to_i
      business_hours_value = business_hours(conversation.inbox, last_resolved_event.event_end_time, conversation.updated_at)
      start_time = last_resolved_event.event_end_time
    else
      time_since_resolved = 0
      business_hours_value = 0
      start_time = conversation.created_at
    end

    create_conversation_opened_event(conversation, time_since_resolved, business_hours_value, start_time)
  end

  private

  def last_client_message(conversation, participant, message)
    client_message = conversation.messages.incoming.where('created_at >= ?', participant.created_at).where('created_at < ?', message.created_at).last
    return unless client_message

    operator_replied_between = conversation.messages.where(message_type: :outgoing, sender_type: 'User', sender_id: message.sender_id)
                                           .where('created_at > ?', client_message.created_at).exists?(['created_at < ?', message.created_at])

    return if operator_replied_between

    client_message
  end

  def create_reply_time_event(conversation, operator_id, client_message, message, waiting_time)
    reporting_event = ReportingEvent.new(
      name: 'reply_time',
      value: waiting_time,
      value_in_business_hours: business_hours(conversation.inbox, client_message.created_at, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: operator_id,
      conversation_id: conversation.id,
      event_start_time: client_message.created_at,
      event_end_time: message.created_at
    )
    reporting_event.save!
  end

  def create_conversation_resolved_events(conversation, start_time, end_time, time_to_resolve)
    user_ids = conversation.conversation_participants.where.not(user_id: nil)
                           .where('created_at >= ?', start_time).distinct.pluck(:user_id)

    user_ids << conversation.assignee_id if user_ids.empty? && conversation.assignee_id.present?
    user_ids.uniq!

    user_ids.each do |user_id|
      build_conversation_resolved_event(conversation, user_id, start_time, end_time, time_to_resolve)
    end

    create_bot_resolved_event(conversation)
  end

  def build_conversation_resolved_event(conversation, user_id, start_time, end_time, time_to_resolve)
    reporting_event = ReportingEvent.new(
      name: 'conversation_resolved',
      value: time_to_resolve,
      value_in_business_hours: business_hours(conversation.inbox, start_time, end_time),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: user_id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: end_time
    )
    reporting_event.save!
  end

  def create_conversation_opened_event(conversation, time_since_resolved, business_hours_value, start_time)
    reporting_event = ReportingEvent.new(
      name: 'conversation_opened',
      value: time_since_resolved,
      value_in_business_hours: business_hours_value,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: conversation.updated_at
    )
    reporting_event.save!
  end

  def create_bot_resolved_event(conversation)
    return unless conversation.inbox.active_bot?
    # We don't want to create a bot_resolved event if there is user interaction on the conversation
    return if conversation.messages.exists?(message_type: :outgoing, sender_type: 'User')
    return if ReportingEvent.exists?(conversation_id: conversation.id, name: 'conversation_bot_resolved')

    bot_resolved_event = ReportingEvent.new(
      name: 'conversation_bot_resolved',
      value: conversation.resolved_at.to_i - conversation.created_at.to_i,
      value_in_business_hours: business_hours(conversation.inbox, conversation.created_at, conversation.resolved_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      event_start_time: conversation.created_at,
      event_end_time: conversation.resolved_at
    )
    bot_resolved_event.save!
  end

  def first_reply_applicable?(message, conversation)
    return false unless message.message_type == 'outgoing'
    return false unless message.sender_type == 'User'

    participant = ConversationParticipant.find_by(conversation_id: conversation.id, user_id: message.sender_id, left_at: nil)
    return false unless participant

    return false if ReportingEvent.exists?(
      conversation_id: conversation.id,
      user_id: message.sender_id,
      name: 'first_response',
      event_start_time: participant.created_at
    )

    true
  end

  def create_first_response_event(conversation, message, assignment_time, first_response_time)
    reporting_event = ReportingEvent.new(
      name: 'first_response',
      value: first_response_time,
      value_in_business_hours: business_hours(conversation.inbox, assignment_time,  message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: message.sender_id,
      conversation_id: conversation.id,
      event_start_time: assignment_time,
      event_end_time: message.created_at
    )
    reporting_event.save!
  end
end
