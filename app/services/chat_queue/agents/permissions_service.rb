class ChatQueue::Agents::PermissionsService
  pattr_initialize [:account!]

  def allowed?(conversation, agent)
    return false if agent.nil? || conversation.nil?

    cid = conversation.id
    allowed = InboxMember.exists?(inbox_id: conversation.inbox_id, user_id: agent.id)
    Rails.logger.info("[QUEUE][allowed][conv=#{cid}] Agent #{agent.id} allowed=#{allowed}")
    allowed
  end
end
