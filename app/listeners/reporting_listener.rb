class ReportingListener < BaseListener
  def conversation_created(event)
    conversation, account = extract_conversation_and_account(event)
    timestamp = event.timestamp

    ::Reports::UpdateAccountIdentity.new(account, timestamp).incr_conversations_count
  end

  def conversation_resolved(event)
    conversation, account = extract_conversation_and_account(event)
    timestamp = event.timestamp

    time_to_resolve = conversation.updated_at.to_i - conversation.created_at.to_i

    if conversation.assignee.present?
      agent = conversation.assignee
      ::Reports::UpdateAgentIdentity.new(account, agent, timestamp).update_avg_resolution_time(time_to_resolve)
      ::Reports::UpdateAgentIdentity.new(account, agent, timestamp).incr_resolutions_count
    end

    ::Reports::UpdateAccountIdentity.new(account, timestamp).update_avg_resolution_time(time_to_resolve)
    ::Reports::UpdateAccountIdentity.new(account, timestamp).incr_resolutions_count
  end

  def first_reply_created(event)
    message, account = extract_message_and_account(event)
    timestamp = event.timestamp

    conversation = message.conversation
    agent = conversation.assignee
    first_response_time = message.created_at.to_i - conversation.created_at.to_i
    ::Reports::UpdateAgentIdentity.new(account, agent, timestamp).update_avg_first_response_time(first_response_time) if agent.present?
    ::Reports::UpdateAccountIdentity.new(account, timestamp).update_avg_first_response_time(first_response_time)
  end

  def message_created(event)
    message, account = extract_message_and_account(event)
    timestamp = event.timestamp

    return unless message.reportable?

    identity = ::Reports::UpdateAccountIdentity.new(account, timestamp)
    message.outgoing? ? identity.incr_outgoing_messages_count : identity.incr_incoming_messages_count
  end
end
