class EventListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    time_to_resolve = conversation.updated_at.to_i - conversation.created_at.to_i

    event = Event.new(
      name: 'conversation_resolved',
      value: time_to_resolve,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id
    )
    event.save
  end

  def first_reply_created(event)
    message = extract_message_and_account(event)[0]
    conversation = message.conversation
    first_response_time = message.created_at.to_i - conversation.created_at.to_i

    event = Event.new(
      name: 'first_response',
      value: first_response_time,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id
    )
    event.save
  end
end
