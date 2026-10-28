# The agents a call rings: the assignee if the conversation has one who can still be
# assigned the inbox, otherwise everyone who could be, keeping only agents whose status is
# online, who take calls and who may open the conversation, as the web does. Socket
# presence is not consulted: a locked phone is offline on the socket and is exactly the
# device a ring push exists for.
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
