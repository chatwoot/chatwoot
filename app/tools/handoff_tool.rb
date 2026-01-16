# frozen_string_literal: true

# Tool for transferring a conversation to a human agent
# Used when the AI agent cannot handle a request or customer explicitly asks for human support
#
# Example usage in agent:
#   chat.with_tools([HandoffTool])
#   # When AI determines it needs human help:
#   response = chat.ask("Transfer to human, I cannot process refunds")
#
class HandoffTool < BaseTool
  description 'Transfer this conversation to a human agent. Use this when: ' \
              '1) The customer explicitly requests to speak with a human, ' \
              '2) The issue is too complex or outside your capabilities, ' \
              '3) The customer seems frustrated and needs personal attention, ' \
              '4) The request involves sensitive operations you cannot perform.'

  param :reason, type: :string, desc: 'Brief explanation of why handoff is needed (visible to agent only)', required: true
  param :priority, type: :string, desc: 'Urgency level: "normal", "high", or "urgent"', required: false
  param :summary, type: :string, desc: 'Summary of the conversation so far to help the human agent', required: false
  param :preferred_team, type: :string, desc: 'Team to route to if available (e.g., "billing", "technical")', required: false

  PRIORITY_LEVELS = %w[normal high urgent].freeze

  def execute(reason:, priority: 'normal', summary: nil, preferred_team: nil)
    validate_context!
    priority = 'normal' unless PRIORITY_LEVELS.include?(priority)

    if playground_mode?
      return success_response({
                                handoff_completed: true,
                                message: '[Playground] Would transfer to human agent',
                                reason: reason,
                                priority: priority
                              })
    end

    # Perform the handoff
    result = perform_handoff(reason: reason, priority: priority, summary: summary, preferred_team: preferred_team)
    success_response(result)
  rescue StandardError => e
    error_response("Handoff failed: #{e.message}")
  end

  private

  def perform_handoff(reason:, priority:, summary:, preferred_team:)
    conversation = current_conversation

    # Deactivate the AI bot for this conversation
    deactivate_bot_for_conversation

    # Update conversation status to open for human agents
    conversation.update!(
      status: :open,
      priority: map_priority(priority),
      snoozed_until: nil
    )

    # Try to assign to an appropriate agent
    assigned_agent = try_assign_agent(preferred_team)

    # Add internal note for the human agent
    add_handoff_note(reason: reason, summary: summary, priority: priority)

    {
      handoff_completed: true,
      conversation_id: conversation.id,
      assigned_agent: assigned_agent,
      message: assigned_agent ? "Transferred to #{assigned_agent.name}" : 'Transferred to available agents'
    }
  end

  def deactivate_bot_for_conversation
    # If there's an agent bot inbox, mark it as inactive for this conversation
    # This prevents the bot from responding to further messages
    agent_bot_inbox = current_conversation.inbox.agent_bot_inbox
    return unless agent_bot_inbox

    # Store handoff state in conversation's custom attributes or context
    current_conversation.update!(custom_attributes: current_conversation.custom_attributes.merge(
      'aloo_handoff_at' => Time.current.iso8601,
      'aloo_handoff_active' => true
    ))
  end

  def try_assign_agent(preferred_team)
    inbox = current_conversation.inbox

    # Get available agents
    available_agents = inbox.assignable_agents

    return nil if available_agents.empty?

    # If preferred team specified, try to find agent from that team
    if preferred_team.present?
      team_agent = find_agent_by_team(available_agents, preferred_team)
      return assign_agent(team_agent) if team_agent
    end

    # Always assign to first available agent for explicit handoff
    # Don't rely on auto-assignment which only works for online agents
    assign_agent(available_agents.first)
  end

  def find_agent_by_team(agents, team_name)
    # Find agents that belong to the specified team
    team = current_account.teams.find_by('LOWER(name) = ?', team_name.downcase)
    return nil unless team

    team_member_ids = team.team_members.pluck(:user_id)
    agents.find { |agent| team_member_ids.include?(agent.id) }
  end

  def assign_agent(agent)
    return nil unless agent

    current_conversation.update!(assignee: agent)
    agent
  end

  def add_handoff_note(reason:, summary:, priority:)
    note_content = build_note_content(reason: reason, summary: summary, priority: priority)

    # Create a private message (internal note) visible only to agents
    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: note_content,
      private: true,
      content_attributes: {
        'aloo_handoff' => true,
        'handoff_reason' => reason,
        'handoff_priority' => priority
      }
    )
  end

  def build_note_content(reason:, summary:, priority:)
    parts = ["🤖 **AI Agent Handoff**\n"]
    parts << "**Priority:** #{priority.capitalize}"
    parts << "**Reason:** #{reason}"
    parts << "\n**Conversation Summary:**\n#{summary}" if summary.present?
    parts.join("\n")
  end

  def map_priority(priority)
    case priority
    when 'urgent' then :urgent
    when 'high' then :high
    else :medium
    end
  end
end
