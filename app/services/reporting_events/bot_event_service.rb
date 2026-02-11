class ReportingEvents::BotEventService
  include ReportingEventHelper

  attr_reader :conversation, :message

  def initialize(conversation, message = nil)
    @conversation = conversation
    @message = message
  end

  def create_bot_resolved_event
    return unless should_create_bot_resolved_event?

    bot_id = find_bot_sender_id
    return if bot_id.blank?

    build_and_save_bot_resolved_event(bot_id)
  end

  def create_bot_handoff_event(time_to_handoff)
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

  def handle_bot_first_response
    start_time = conversation.created_at
    first_response_time = message.created_at.to_i - start_time.to_i
    return if first_response_time <= 0

    build_and_save_bot_first_response_event(start_time, first_response_time)
  end

  def handle_bot_reply_time
    client_message = find_last_client_message_for_bot
    return unless client_message
    return if bot_already_replied_to_message?(client_message)

    waiting_time = message.created_at.to_i - client_message.created_at.to_i
    return if waiting_time <= 0

    build_and_save_bot_reply_event(client_message, waiting_time)
  end

  def bot_message_applicable?
    message.message_type == 'outgoing' && message.sender_type.in?(['AgentBot', 'Captain::Assistant'])
  end

  def bot_first_response_applicable?
    return false if ReportingEvent.exists?(conversation_id: conversation.id, name: 'bot_first_response')

    !prior_bot_message_exists?
  end

  def bot_handoff_event_exists?
    ReportingEvent.exists?(conversation_id: conversation.id, name: 'conversation_bot_handoff')
  end

  private

  def should_create_bot_resolved_event?
    return false unless conversation.inbox.active_bot?
    return false if conversation.messages.exists?(message_type: :outgoing, sender_type: 'User')
    return false if ReportingEvent.exists?(conversation_id: conversation.id, name: 'conversation_bot_resolved')

    true
  end

  def find_bot_sender_id
    conversation.messages
                .where(message_type: :outgoing)
                .where(sender_type: ['AgentBot', 'Captain::Assistant'])
                .pick(:sender_id)
  end

  def build_and_save_bot_resolved_event(bot_id)
    bot_resolved_event = ReportingEvent.new(bot_resolved_event_attributes(bot_id))
    bot_resolved_event.save!
  end

  def bot_resolved_event_attributes(bot_id)
    {
      name: 'conversation_bot_resolved',
      value: conversation.resolved_at.to_i - conversation.created_at.to_i,
      value_in_business_hours: business_hours(conversation.inbox, conversation.created_at, conversation.resolved_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      agent_bot_id: bot_id,
      event_start_time: conversation.created_at,
      event_end_time: conversation.resolved_at
    }
  end

  def prior_bot_message_exists?
    conversation.messages
                .where(message_type: :outgoing)
                .where(sender_type: ['AgentBot', 'Captain::Assistant'])
                .exists?(['created_at < ?', message.created_at])
  end

  def build_and_save_bot_first_response_event(start_time, first_response_time)
    reporting_event = ReportingEvent.new(bot_first_response_event_attributes(start_time, first_response_time))
    reporting_event.save!
  end

  def bot_first_response_event_attributes(start_time, first_response_time)
    {
      name: 'bot_first_response',
      value: first_response_time,
      value_in_business_hours: business_hours(conversation.inbox, start_time, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      agent_bot_id: message.sender_id,
      event_start_time: start_time,
      event_end_time: message.created_at
    }
  end

  def find_last_client_message_for_bot
    conversation.messages.incoming
                .where('created_at < ?', message.created_at)
                .last
  end

  def bot_already_replied_to_message?(client_message)
    conversation.messages
                .where(message_type: :outgoing)
                .where(sender_type: ['AgentBot', 'Captain::Assistant'])
                .where('created_at > ?', client_message.created_at)
                .exists?(['created_at < ?', message.created_at])
  end

  def build_and_save_bot_reply_event(client_message, waiting_time)
    reporting_event = ReportingEvent.new(bot_reply_event_attributes(client_message, waiting_time))
    reporting_event.save!
  end

  def bot_reply_event_attributes(client_message, waiting_time)
    {
      name: 'bot_reply_time',
      value: waiting_time,
      value_in_business_hours: business_hours(conversation.inbox, client_message.created_at, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      agent_bot_id: message.sender_id,
      event_start_time: client_message.created_at,
      event_end_time: message.created_at
    }
  end
end
