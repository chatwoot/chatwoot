module ConversationMessageSummaryQueries
  def message_summary_rows(conversation_ids)
    where(id: conversation_ids).pluck(
      :id,
      latest_summary_message_id(Message.message_types.values),
      latest_summary_message_id(Message.message_types.except('activity').values),
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
    Message.unscoped.where(
      summary_messages_table[:conversation_id].eq(arel_table[:id]).and(summary_messages_table[:account_id].eq(arel_table[:account_id]))
    )
  end

  # The dashboard seeds the message thread from this message and paginates backward by id.
  # Break created_at ties by id so a lower-id activity cannot hide a same-second input_csat survey.
  def latest_summary_message_id(message_types)
    candidates = Arel::Table.new(:message_candidates)
    source = Arel::Nodes::TableAlias.new(summary_message_candidates(message_types), candidates.name)
    query = Message.unscoped.from(source).select(candidates[:id]).order(candidates[:created_at].desc, candidates[:id].desc).limit(1)
    Arel::Nodes::Grouping.new(query.arel.ast)
  end

  # Selecting a candidate per type uses the existing (conversation_id, account_id, message_type, created_at) index.
  def summary_message_candidates(message_types)
    candidates = message_types.map do |message_type|
      messages = summary_messages.where(message_type: message_type).reorder(created_at: :desc, id: :desc)
      Arel::Nodes::Grouping.new(messages.limit(1).select(:id, :created_at).arel.ast)
    end
    union = candidates.reduce { |left, right| Arel::Nodes::UnionAll.new(left, right) }
    Arel::Nodes::Grouping.new(union)
  end

  def summary_messages_table
    Message.arel_table
  end
end
