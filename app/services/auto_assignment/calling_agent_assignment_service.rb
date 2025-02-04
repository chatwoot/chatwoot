class AutoAssignment::CallingAgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignees
    round_robin_manage_service.available_agents(allowed_agent_ids: allowed_online_agent_ids)
  end

  def activity_message_params(content)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: content }
  end

  def perform
    assignees = find_assignees
    return assignees if assignees.present?

    Rails.logger.info "No agents were assigned, #{conversation.account_id}"
    content = 'Conversation not assigned to any agent as no agents were online'
    Conversations::ActivityMessageJob.set(wait: 15.seconds).perform_later(conversation,
                                                                          activity_message_params(content))
    []
  end

  private

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(conversation.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def allowed_online_agent_ids
    # We want to perform roundrobin only over online agents
    # Hence taking an intersection of online agents and allowed member ids

    # the online user ids are string, since its from redis, allowed member ids are integer, since its from active record
    Rails.logger.info "Allowed agent ids: #{allowed_agent_ids.inspect}"
    Rails.logger.info "Online agent ids: #{online_agent_ids.inspect}"
    @allowed_online_agent_ids ||= online_agent_ids & allowed_agent_ids&.map(&:to_s)
  end

  def round_robin_manage_service
    @round_robin_manage_service ||= AutoAssignment::CallingRoundRobinService.new(account: conversation.account)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS_CALLING, account_id: conversation.account_id)
  end
end
