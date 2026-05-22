module Conversations::UnreadCounts::StoreKeys
  def inbox_key(account_id, inbox_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_INBOX, account_id: account_id, inbox_id: inbox_id)
  end

  def label_inbox_key(account_id, label_id, inbox_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_LABEL_INBOX, account_id: account_id, label_id: label_id, inbox_id: inbox_id)
  end

  def team_inbox_key(account_id, team_id, inbox_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_TEAM_INBOX, account_id: account_id, team_id: team_id, inbox_id: inbox_id)
  end

  def inbox_unassigned_key(account_id, inbox_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_INBOX_UNASSIGNED, account_id: account_id, inbox_id: inbox_id)
  end

  def inbox_assignee_key(account_id, inbox_id, user_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_INBOX_ASSIGNEE, account_id: account_id, inbox_id: inbox_id, user_id: user_id)
  end

  def label_inbox_unassigned_key(account_id, label_id, inbox_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_LABEL_INBOX_UNASSIGNED, account_id: account_id, label_id: label_id, inbox_id: inbox_id)
  end

  def label_inbox_assignee_key(account_id, label_id, inbox_id, user_id)
    format(
      Redis::Alfred::UNREAD_CONVERSATIONS_LABEL_INBOX_ASSIGNEE,
      account_id: account_id,
      label_id: label_id,
      inbox_id: inbox_id,
      user_id: user_id
    )
  end

  def team_inbox_unassigned_key(account_id, team_id, inbox_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_TEAM_INBOX_UNASSIGNED, account_id: account_id, team_id: team_id, inbox_id: inbox_id)
  end

  def team_inbox_assignee_key(account_id, team_id, inbox_id, user_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_TEAM_INBOX_ASSIGNEE, account_id: account_id, team_id: team_id, inbox_id: inbox_id, user_id: user_id)
  end
end
