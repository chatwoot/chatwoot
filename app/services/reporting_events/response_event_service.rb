class ReportingEvents::ResponseEventService
  include ReportingEventHelper

  attr_reader :conversation, :message, :participant

  def initialize(conversation, message, participant = nil)
    @conversation = conversation
    @message = message
    @participant = participant
  end

  def create_first_response_event
    assignment_time = participant.created_at
    return if first_response_event_exists?(assignment_time)

    first_response_time = message.created_at.to_i - assignment_time.to_i
    return if first_response_time <= 0

    build_and_save_first_response_event(assignment_time, first_response_time)
  end

  def create_first_response_from_open_event
    start_time = determine_first_response_start_time
    return if first_response_from_open_exists?(start_time)

    first_response_time = message.created_at.to_i - start_time.to_i
    return if first_response_time <= 0

    build_and_save_first_response_from_open_event(start_time, first_response_time)
  end

  def create_reply_time_event(operator_id, client_message, waiting_time)
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

  def last_client_message_for_operator
    client_message = find_client_message_after_participant_joined
    return unless client_message
    return if operator_replied_between?(client_message)

    client_message
  end

  private

  def first_response_event_exists?(assignment_time)
    ReportingEvent.exists?(
      conversation_id: conversation.id,
      user_id: message.sender_id,
      name: 'first_response',
      event_start_time: assignment_time
    )
  end

  def build_and_save_first_response_event(assignment_time, first_response_time)
    reporting_event = ReportingEvent.new(
      name: 'first_response',
      value: first_response_time,
      value_in_business_hours: business_hours(conversation.inbox, assignment_time, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: message.sender_id,
      conversation_id: conversation.id,
      event_start_time: assignment_time,
      event_end_time: message.created_at
    )
    reporting_event.save!
  end

  def determine_first_response_start_time
    conversation_opened_event = ReportingEvent.where(
      conversation_id: conversation.id,
      name: 'conversation_opened'
    ).where('event_end_time <= ?', message.created_at)
                                              .order(event_end_time: :desc)
                                              .first

    conversation_opened_event&.event_end_time || conversation.created_at
  end

  def first_response_from_open_exists?(start_time)
    ReportingEvent.exists?(
      conversation_id: conversation.id,
      user_id: message.sender_id,
      name: 'first_response_from_open',
      event_start_time: start_time
    )
  end

  def build_and_save_first_response_from_open_event(start_time, first_response_time)
    reporting_event = ReportingEvent.new(
      name: 'first_response_from_open',
      value: first_response_time,
      value_in_business_hours: business_hours(conversation.inbox, start_time, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: message.sender_id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: message.created_at
    )
    reporting_event.save!
  end

  def find_client_message_after_participant_joined
    conversation.messages.incoming
                .where('created_at >= ?', participant.created_at)
                .where('created_at < ?', message.created_at)
                .last
  end

  def operator_replied_between?(client_message)
    conversation.messages
                .where(message_type: :outgoing, sender_type: 'User', sender_id: message.sender_id)
                .where('created_at > ?', client_message.created_at)
                .exists?(['created_at < ?', message.created_at])
  end
end
