module ConversationMessageSummaryQueries
  def message_summary_rows(conversation_ids)
    where(id: conversation_ids).pluck(
      :id,
      latest_summary_message_id(summary_messages),
      latest_summary_message_id(summary_messages.where.not(message_type: :activity)),
      unread_incoming_messages_arel { |messages| limited_summary_count(messages) }
    )
  end

  private

  def limited_summary_count(messages)
    selected = messages.reorder(created_at: :desc).limit(Conversation::UNREAD_INCOMING_MESSAGES_LIMIT).select(:id)
    count_query = Message.unscoped.from(selected, :unread_messages).select(Arel.star.count)
    Arel::Nodes::Grouping.new(count_query.arel.ast)
  end

  # Messages of the conversation row in the outer query.
  def summary_messages
    messages = Message.arel_table
    Message.unscoped.where(messages[:conversation_id].eq(arel_table[:id]).and(messages[:account_id].eq(arel_table[:account_id])))
  end

  # The dashboard seeds the message thread from this message and paginates backward by id.
  # Break created_at ties by id so a lower-id activity cannot hide a same-second input_csat survey.
  #
  # Do not split this probe by message type. Postgres plans a correlated subquery once, without
  # the conversation's values, and that plan filters message_type while it walks the conversation
  # newest first. A probe for a type the conversation rarely has would then read most of its history.
  def latest_summary_message_id(messages)
    query = messages.reorder(created_at: :desc, id: :desc).limit(1).select(:id)
    Arel::Nodes::Grouping.new(query.arel.ast)
  end
end
