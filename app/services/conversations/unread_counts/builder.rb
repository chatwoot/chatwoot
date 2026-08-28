class Conversations::UnreadCounts::Builder
  BATCH_SIZE = 1000

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def build_base!
    store.clear_account!(account.id)
    write_memberships(assignment: false)
    store.mark_base_ready!(account.id)
  end

  def build_assignment!
    store.clear_assignment!(account.id)
    write_memberships(assignment: true)
    store.mark_assignment_ready!(account.id)
  end

  def build_all!
    build_base!
    build_assignment!
  end

  private

  def write_memberships(assignment:)
    unread_conversations.in_batches(of: BATCH_SIZE) do |relation|
      relation = relation.where(assignee_agent_bot_id: nil) if assignment
      columns = %i[id inbox_id assignee_id cached_label_list team_id]
      memberships = relation.pluck(*columns).map do |id, inbox_id, assignee_id, cached_label_list, team_id|
        {
          conversation_id: id,
          inbox_id: inbox_id,
          assignee_id: assignee_id,
          team_id: team_id,
          label_ids: label_ids_for(cached_label_list)
        }
      end

      store.add_memberships(account_id: account.id, memberships: memberships, assignment: assignment)
    end
  end

  # Uses EXISTS subqueries (rather than LEFT JOINs on :messages and :message_reactions) so each
  # conversation is scanned once instead of producing a messages x reactions cartesian product
  # per conversation, and so we never touch outgoing messages, which this check never needed.
  def unread_conversations
    account.conversations
           .open
           .where(unread_message_exists.or(unread_reaction_exists))
  end

  def unread_message_exists
    Arel::Nodes::Exists.new(unread_message_subquery.arel)
  end

  def unread_reaction_exists
    Arel::Nodes::Exists.new(unread_reaction_subquery.arel)
  end

  def unread_message_subquery
    Message.select(1).where(unread_message_condition).where(correlate_to_conversation(Message.arel_table))
  end

  def unread_reaction_subquery
    MessageReaction.select(1).where(unread_reaction_condition).where(correlate_to_conversation(MessageReaction.arel_table))
  end

  def correlate_to_conversation(table)
    table[:conversation_id].eq(Conversation.arel_table[:id])
  end

  def unread_message_condition
    messages = Message.arel_table

    messages[:account_id].eq(account.id)
                         .and(messages[:message_type].eq(Message.message_types[:incoming]))
                         .and(last_seen_null_or_before(messages[:created_at]))
  end

  def unread_reaction_condition
    reactions = MessageReaction.arel_table

    reactions[:account_id].eq(account.id)
                          .and(reactions[:direction].eq(MessageReaction.directions[:incoming]))
                          .and(reactions[:status].eq(MessageReaction.statuses[:active]))
                          .and(last_seen_null_or_before(reactions[:created_at]))
  end

  def last_seen_null_or_before(timestamp_column)
    conversations = Conversation.arel_table
    conversations[:agent_last_seen_at].eq(nil).or(timestamp_column.gt(conversations[:agent_last_seen_at]))
  end

  def label_ids_for(cached_label_list)
    label_titles = cached_label_list.to_s.split(',').map(&:strip).compact_blank
    labels_by_title.values_at(*label_titles).compact
  end

  def labels_by_title
    @labels_by_title ||= account.labels.pluck(:title, :id).to_h
  end

  def store
    ::Conversations::UnreadCounts::Store
  end
end
