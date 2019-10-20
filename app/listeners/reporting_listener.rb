class ReportingListener < BaseListener
  def conversation_created(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    ::Reports::UpdateAccountIdentity.new(account, timestamp).incr_conversations_count
  end

  def conversation_resolved(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    time_to_resolve = conversation.updated_at.to_i - conversation.created_at.to_i
    agent = conversation.assignee
    ::Reports::UpdateAgentIdentity.new(account, agent, timestamp).update_avg_resolution_time(time_to_resolve)
    ::Reports::UpdateAgentIdentity.new(account, agent, timestamp).incr_resolutions_count
    ::Reports::UpdateAccountIdentity.new(account, timestamp).update_avg_resolution_time(time_to_resolve)
    ::Reports::UpdateAccountIdentity.new(account, timestamp).incr_resolutions_count
  end

  def first_reply_created(event)
    message, account, timestamp = extract_message_and_account(event)
    conversation = message.conversation
    agent = conversation.assignee
    first_response_time = message.created_at.to_i - conversation.created_at.to_i
    ::Reports::UpdateAgentIdentity.new(account, agent, timestamp).update_avg_first_response_time(first_response_time) if agent.present?
    ::Reports::UpdateAccountIdentity.new(account, timestamp).update_avg_first_response_time(first_response_time)
  end

  def message_created(event)
    message, account, timestamp = extract_message_and_account(event)
    if message.outgoing?
      ::Reports::UpdateAccountIdentity.new(account, timestamp).incr_outgoing_messages_count
    else
      ::Reports::UpdateAccountIdentity.new(account, timestamp).incr_incoming_messages_count
    end
  end
end
