# Finds what Conversations::MessageSummary reads, for many conversations in one statement.
#
# Each value is a subquery that reads the conversation's messages newest first and stops early.
# Do not split these by message type: Postgres plans a subquery without the conversation's
# values, and a probe for a type the conversation rarely has would read its whole history.
class Conversations::MessageSummaryQuery
  Row = Data.define(:conversation_id, :last_message_id, :last_non_activity_message_id, :unread_count)

  def initialize(conversation_ids)
    @conversation_ids = conversation_ids
  end

  def rows
    values = Conversation.where(id: @conversation_ids).pluck(:id, last_message_id, last_non_activity_message_id, unread_count)
    values.map { |row_values| Row.new(*row_values) }
  end

  private

  def last_message_id
    subquery(conversation_messages.order(created_at: :desc, id: :desc).limit(1).select(:id))
  end

  def last_non_activity_message_id
    subquery(conversation_messages.where.not(message_type: :activity).order(created_at: :desc).limit(1).select(:id))
  end

  def unread_count
    unread_messages = conversation_messages.incoming.where(messages[:created_at].gt(agent_last_seen_at))
                                           .order(created_at: :desc).limit(Conversation::UNREAD_INCOMING_MESSAGES_LIMIT).select(:id)
    subquery(Message.unscoped.from(unread_messages, :unread_messages).select(Arel.star.count))
  end

  # A conversation that no agent has seen counts every incoming message.
  # The comparison stays on created_at so that Postgres can use it in the index condition.
  def agent_last_seen_at
    Arel::Nodes::NamedFunction.new('COALESCE', [conversations[:agent_last_seen_at], Arel::Nodes.build_quoted('-infinity')])
  end

  # Messages of the conversation row in the outer query
  def conversation_messages
    Message.unscoped.where(messages[:conversation_id].eq(conversations[:id]).and(messages[:account_id].eq(conversations[:account_id])))
  end

  def subquery(relation)
    Arel::Nodes::Grouping.new(relation.arel.ast)
  end

  def messages
    Message.arel_table
  end

  def conversations
    Conversation.arel_table
  end
end
