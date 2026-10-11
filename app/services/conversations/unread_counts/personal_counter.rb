class Conversations::UnreadCounts::PersonalCounter < Conversations::UnreadCounts::Counter
  def perform
    inboxes = Hash.new(0)
    labels = Hash.new(0)
    teams = Hash.new(0)
    label_ids = account.labels.where(show_on_sidebar: true).pluck(:title, :id).to_h
    team_ids = visible_team_ids.to_set

    personal_unread_conversations.pluck(:inbox_id, :team_id, :cached_label_list).each do |inbox_id, team_id, cached_labels|
      inboxes[inbox_id.to_s] += 1
      teams[team_id.to_s] += 1 if team_ids.include?(team_id)
      increment_labels(labels, label_ids, cached_labels)
    end
    { all_count: inboxes.values.sum, inboxes: inboxes, labels: labels, teams: teams }
  end

  private

  def increment_labels(counts, ids, titles)
    titles.to_s.split(',').map(&:strip).uniq.each do |title|
      label_id = ids[title]
      counts[label_id.to_s] += 1 if label_id
    end
  end

  def personal_unread_conversations
    messages = Message.arel_table
    incoming = messages.project(Arel.sql('1')).where(
      Conversation.unread_messages_condition(messages, Conversation.arel_table, user: user, account: account)
    )
    relation = account.conversations.open.where(inbox_id: visible_inbox_ids).where(incoming.exists)
    return relation unless assignment_mode?

    assignee_ids = permission_mode == :mine ? [user.id] : [nil, user.id]
    relation.where(assignee_agent_bot_id: nil, assignee_id: assignee_ids)
  end
end
