class AutoAssignment::AgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignee
    round_robin_manage_service.available_agent(allowed_agent_ids: allowed_online_agent_ids)
  end

  def activity_message_params(content)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: content }
  end

  def perform
    new_assignee = find_assignee
    if new_assignee.nil?
      Rails.logger.info "No agents were assigned, #{conversation.account_id}"
      content = if assign_even_if_offline_enabled?
                  'Conversation not assigned to any agent'
                else
                  'Conversation not assigned to any agent as no agents were online'
                end
      Conversations::ActivityMessageJob.set(wait: 15.seconds).perform_later(conversation,
                                                                            activity_message_params(content))
    else
      conversation.update(assignee: new_assignee)
    end
  end

  private

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(conversation.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def allowed_online_agent_ids
    return all_allowed_agent_ids if assign_even_if_offline_enabled?

    # We want to perform roundrobin only over online agents
    # Hence taking an intersection of online agents and allowed member ids
    @allowed_online_agent_ids ||= online_agent_ids_for_assignment
  end

  def all_allowed_agent_ids
    allowed_agent_ids&.map(&:to_s)
  end

  def online_agent_ids_for_assignment
    # the online user ids are string, since its from redis, allowed member ids are integer, since its from active record
    account_id = conversation.account_id
    case account_id
    when 1058
      all_allowed_agent_ids
    else
      online_agent_ids & all_allowed_agent_ids
    end
  end

  def round_robin_manage_service
    @round_robin_manage_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: conversation.inbox_id)
  end

  def assign_even_if_offline_enabled?
    conversation.inbox.auto_assignment_config&.dig('assign_even_if_offline') == true
  end
end
