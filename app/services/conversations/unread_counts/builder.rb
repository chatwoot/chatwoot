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

  def unread_conversations
    account.conversations
           .open
           .left_joins(:messages, :message_reactions)
           .where(unread_since_last_seen_condition)
           .distinct
  end

  def unread_since_last_seen_condition
    unread_message_condition.or(unread_reaction_condition)
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
