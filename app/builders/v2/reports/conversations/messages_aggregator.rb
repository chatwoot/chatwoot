class V2::Reports::Conversations::MessagesAggregator < V2::Reports::Conversations::BaseAggregator
  private

  def compute_metrics
    incoming_count, outgoing_count = base_relation.pluck(
      Arel.sql(count_sql(Message.message_types[:incoming])),
      Arel.sql(count_sql(Message.message_types[:outgoing]))
    ).first || [0, 0]

    {
      incoming_messages_count: incoming_count || 0,
      outgoing_messages_count: outgoing_count || 0
    }
  end

  def base_relation
    scope.messages
         .where(account_id: account.id, created_at: range)
         .unscope(:order)
         .reorder(nil)
  end

  def count_sql(message_type)
    "COUNT(*) FILTER (WHERE message_type = #{message_type})"
  end
end
