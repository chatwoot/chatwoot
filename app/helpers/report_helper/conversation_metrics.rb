module ReportHelper::ConversationMetrics
  private

  def conversations_count
    get_grouped_values(conversations).count
  end

  def incoming_messages_count
    get_grouped_values(incoming_messages).count
  end

  def outgoing_messages_count
    get_grouped_values(outgoing_messages).count
  end

  def resolutions_count
    get_grouped_values(resolutions).count
  end

  def conversations
    scope.conversations.where(account_id: account.id, created_at: range)
  end

  def incoming_messages
    scope.messages.where(account_id: account.id, created_at: range).incoming.unscope(:order)
  end

  def outgoing_messages
    scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
  end

  def resolutions
    scope.reporting_events.where(account_id: account.id, name: :conversation_resolved, created_at: range)
  end
end
