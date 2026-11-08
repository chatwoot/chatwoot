# Locked phones can receive pushes without a live socket.
class Voice::RingRecipients
  pattr_initialize [:inbox!, :conversation!]

  def agents
    online = AccountUser.where(account_id: inbox.account_id, user_id: candidates.map(&:id), availability: :online, accepts_calls: true)
                        .index_by(&:user_id)
    candidates.select { |user| online[user.id] && can_open_conversation?(user, online[user.id]) }
  end

  private

  def candidates
    @candidates ||= begin
      assignable = inbox.assignable_agents.to_a
      assignee = conversation.assignee
      assignee && assignable.include?(assignee) ? [assignee] : assignable
    end
  end

  def can_open_conversation?(user, account_user)
    ConversationPolicy.new({ user: user, account: inbox.account, account_user: account_user }, conversation).show?
  end
end
