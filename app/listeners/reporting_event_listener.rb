class ReportingEventListener < BaseListener
  include ReportingEventHelper

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    return if conversation.resolved_at.blank?

    log_prefix = "[ResolutionMetric] conv_id=#{conversation.id} inbox_id=#{conversation.inbox_id}"

    start_time = conversation.created_at
    end_time = conversation.resolved_at
    time_to_resolve = end_time - start_time
    return if time_to_resolve <= 0

    service = resolution_service(conversation)
    service.create_conversation_resolved_events(start_time, end_time, time_to_resolve)

    if conversation.inbox.active_bot?
      without_bot_start_time = resolve_without_bot_start_time(conversation, log_prefix)
      return if without_bot_start_time.nil?
    else
      without_bot_start_time = start_time
      Rails.logger.info("#{log_prefix} | has_bot=false | without_bot_start_time=conversation_start=#{start_time.iso8601}")
    end

    Rails.logger.info(
      "#{log_prefix} | " \
      'creating resolution_time_without_bot | ' \
      "without_bot_start_time=#{without_bot_start_time.iso8601} | " \
      "resolved_at=#{end_time.iso8601} | " \
      "time_without_bot=#{(end_time - without_bot_start_time).to_i}s | " \
      "total_resolution_time=#{time_to_resolve.to_i}s | " \
      "bot_time=#{(without_bot_start_time - start_time).to_i}s"
    )

    service.create_resolution_without_bot_events(without_bot_start_time)
  end

  def first_reply_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation

    return unless outgoing_user_message?(message)

    # Handle operator first response
    participant = ConversationParticipant.find_by(conversation_id: conversation.id, user_id: message.sender_id, left_at: nil)
    return if participant.blank?
    return if participant.created_at.blank?

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

  def message_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation

    return unless bot_message_applicable?(message)

    # Bot first response
    handle_bot_first_response(conversation, message) if bot_first_response_applicable?(conversation, message)

    # Bot reply time
    handle_bot_reply_time(conversation, message)
  end

  private

  def resolve_without_bot_start_time(conversation, log_prefix)
    operator_first_message_at = first_operator_message_at(conversation)
  
    return nil if operator_first_message_at.nil?
    return nil if operator_first_message_at > conversation.resolved_at
  
    Rails.logger.info(
      "#{log_prefix} | has_bot=true | source=first_operator_message | " \
      "without_bot_start_time=#{operator_first_message_at.iso8601}"
    )
  
    operator_first_message_at
  end

  def first_operator_message_at(conversation)
    conversation.messages
                .where(message_type: :outgoing, sender_type: 'User')
                .where('created_at >= ?', conversation.created_at)
                .minimum(:created_at)
  end

  def find_active_participant(conversation, user_id)
    ConversationParticipant.find_by(
      conversation_id: conversation.id,
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
  
    bot_id = conversation.messages
                        .where(message_type: :outgoing)
                        .where(sender_type: ['AgentBot', 'Captain::Assistant'])
                        .pick(:sender_id)
  
    return if bot_id.blank?
  
    bot_resolved_event = ReportingEvent.new(
      name: 'conversation_bot_resolved',
      value: conversation.resolved_at.to_i - conversation.created_at.to_i,
      value_in_business_hours: business_hours(conversation.inbox, conversation.created_at, conversation.resolved_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      agent_bot_id: bot_id,
      event_start_time: conversation.created_at,
      event_end_time: conversation.resolved_at
    )
    bot_resolved_event.save!
  end

  def first_reply_applicable?(message, conversation)
    return false unless message.message_type == 'outgoing'
    return false unless message.sender_type == 'User'

    participant = ConversationParticipant.find_by(
      conversation_id: conversation.id,
      user_id: message.sender_id,
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

  def bot_message_applicable?(message)
    return false unless message.message_type == 'outgoing'
    return false unless message.sender_type.in?(['AgentBot', 'Captain::Assistant'])
    
    true
  end

  def bot_first_response_applicable?(conversation, message)
    # Check if this is the first bot response in the conversation
    return false if ReportingEvent.exists?(
      conversation_id: conversation.id,
      name: 'bot_first_response'
    )

    # Ensure there's no prior bot message
    prior_bot_message = conversation.messages
                                    .where(message_type: :outgoing)
                                    .where(sender_type: ['AgentBot', 'Captain::Assistant'])
                                    .where('created_at < ?', message.created_at)
                                    .exists?

    !prior_bot_message
  end

  def handle_bot_first_response(conversation, message)
    start_time = conversation.created_at
    first_response_time = message.created_at.to_i - start_time.to_i
    return if first_response_time <= 0

    reporting_event = ReportingEvent.new(
      name: 'bot_first_response',
      value: first_response_time,
      value_in_business_hours: business_hours(conversation.inbox, start_time, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      agent_bot_id: message.sender_id,
      event_start_time: start_time,
      event_end_time: message.created_at
    )
    reporting_event.save!
  end

  def handle_bot_reply_time(conversation, message)
    # Find the last client message before this bot message
    client_message = conversation.messages.incoming
                                 .where('created_at < ?', message.created_at)
                                 .last

    return unless client_message

    # Check if bot already replied to this client message
    bot_replied_between = conversation.messages
                                      .where(message_type: :outgoing)
                                      .where(sender_type: ['AgentBot', 'Captain::Assistant'])
                                      .where('created_at > ?', client_message.created_at)
                                      .where('created_at < ?', message.created_at)
                                      .exists?

    return if bot_replied_between

    waiting_time = message.created_at.to_i - client_message.created_at.to_i
    return if waiting_time <= 0

    reporting_event = ReportingEvent.new(
      name: 'bot_reply_time',
      value: waiting_time,
      value_in_business_hours: business_hours(conversation.inbox, client_message.created_at, message.created_at),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      agent_bot_id: message.sender_id,
      event_start_time: client_message.created_at,
      event_end_time: message.created_at
    )
    reporting_event.save!
  end

  def create_bot_resolve_time_event(conversation)
    return unless conversation.inbox.active_bot?
    # Only create if conversation was resolved by bot (no user interaction)
    return if conversation.messages.exists?(message_type: :outgoing, sender_type: 'User')
    return if ReportingEvent.exists?(conversation_id: conversation.id, name: 'bot_resolve_time')

    start_time = conversation.created_at
    end_time = conversation.resolved_at
    resolve_time = end_time.to_i - start_time.to_i
    return if resolve_time <= 0

    reporting_event = ReportingEvent.new(
      name: 'bot_resolve_time',
      value: resolve_time,
      value_in_business_hours: business_hours(conversation.inbox, start_time, end_time),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      agent_bot_id: message.sender_id,
      event_start_time: start_time,
      event_end_time: end_time
    )
    reporting_event.save!
  end
end