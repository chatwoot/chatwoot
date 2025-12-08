class ChatQueue::Agents::SelectorService
  pattr_initialize [:account!]

  def pick_best_agent_for(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][pick][conv=#{cid}] Selecting best agent")

    online_agents.each do |agent|
      allowed = allowed_for_conversation?(conversation, agent)
      available = available?(agent)

      Rails.logger.info("[QUEUE][pick][conv=#{cid}] Agent #{agent.id}: allowed=#{allowed}, available=#{available}")

      next unless allowed && available

      Rails.logger.info("[QUEUE][pick][conv=#{cid}] Selected agent #{agent.id}")
      return agent
    end

    Rails.logger.info("[QUEUE][pick][conv=#{cid}] No agent found")
    nil
  end

  def online_agents
    ChatQueue::Agents::OnlineAgentsService.new(account: account).list.filter_map { |id| User.find_by(id: id) }
  end

  private

  def allowed_for_conversation?(conversation, agent)
    ChatQueue::Agents::PermissionsService.new(account: account).allowed?(conversation, agent)
  end

  def available?(agent)
    ChatQueue::Agents::AvailabilityService.new(account: account).available?(agent)
  end
end
