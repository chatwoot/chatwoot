module ConversationsUnreadCountsHelpers
  def create_unread_conversation(account:, inbox:, labels: [], assignee: nil, team: nil)
    create(:team_member, user: assignee, team: team) if assignee.present? && team.present? && !team.members.exists?(assignee.id)

    conversation = create(:conversation, account: account, inbox: inbox, assignee: assignee, team: team, agent_last_seen_at: 1.hour.ago)
    conversation.update_labels(labels) if labels.present?

    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, created_at: 5.minutes.ago)
    conversation
  end
end
