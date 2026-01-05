# frozen_string_literal: true

# Tool for assigning conversations to teams or agents
# Used by AI agent to route conversations to appropriate teams or specialists
#
# Example usage in agent:
#   chat.with_tools([AssignMcp])
#   response = chat.ask("This is a billing issue, assign to the billing team")
#
class AssignMcp < BaseMcp
  description 'Assign this conversation to a team or specific agent. Use when: ' \
              '1) The issue requires specialized expertise, ' \
              '2) Routing to a specific department is needed, ' \
              '3) Escalating to a senior agent.'

  param :team_name, type: :string, desc: 'Name of the team to assign to', required: false
  param :agent_email, type: :string, desc: 'Email of the agent to assign to', required: false
  param :reason, type: :string, desc: 'Explanation for this assignment', required: false

  def execute(team_name: nil, agent_email: nil, reason: nil)
    validate_context!
    return error_response('Must provide either team_name or agent_email') if team_name.blank? && agent_email.blank?

    perform_assignment(team_name: team_name, agent_email: agent_email, reason: reason)
  rescue StandardError => e
    handle_error(team_name: team_name, agent_email: agent_email, error: e)
  end

  private

  def perform_assignment(team_name:, agent_email:, reason:)
    result = build_assignment_result(team_name: team_name, agent_email: agent_email)
    return result if result.is_a?(Hash) && result[:success] == false

    add_assignment_note(reason: reason, team: result[:team], agent: result[:agent]) if reason.present?
    log_and_track(team_name: team_name, agent_email: agent_email, result: result)
    build_success_response(result)
  end

  def build_assignment_result(team_name:, agent_email:)
    result = { team_assigned: false, agent_assigned: false }

    if team_name.present?
      team_result = assign_to_team(team_name)
      return error_response(team_result[:error]) if team_result[:error]

      result[:team_assigned] = true
      result[:team] = team_result[:team]
    end

    if agent_email.present?
      agent_result = assign_to_agent(agent_email)
      return error_response(agent_result[:error]) if agent_result[:error]

      result[:agent_assigned] = true
      result[:agent] = agent_result[:agent]
    end

    result
  end

  def log_and_track(team_name:, agent_email:, result:)
    log_execution({ team_name: team_name, agent_email: agent_email, reason: true },
                  { success: true, team_assigned: result[:team_assigned], agent_assigned: result[:agent_assigned] })
    track_in_context(input: { team_name: team_name, agent_email: agent_email }, output: result)
  end

  def build_success_response(result)
    success_response(
      assignment_completed: true, team_assigned: result[:team_assigned], team_name: result[:team]&.name,
      agent_assigned: result[:agent_assigned], agent_name: result[:agent]&.name, message: build_success_message(result)
    )
  end

  def handle_error(team_name:, agent_email:, error:)
    log_execution({ team_name: team_name, agent_email: agent_email }, {}, success: false, error_message: error.message)
    error_response("Failed to assign conversation: #{error.message}")
  end

  def assign_to_team(team_name)
    team = current_account.teams.find_by('LOWER(name) = ?', team_name.downcase.strip)
    return { error: "Team '#{team_name}' not found" } unless team

    current_conversation.update!(team_id: team.id)
    { team: team }
  end

  def assign_to_agent(agent_email)
    inbox = current_conversation.inbox
    assignable_agents = inbox.assignable_agents

    agent = assignable_agents.find { |a| a.email.downcase == agent_email.downcase.strip }
    return { error: "Agent '#{agent_email}' not found or not assignable to this inbox" } unless agent

    current_conversation.update!(assignee_id: agent.id)
    { agent: agent }
  end

  def add_assignment_note(reason:, team:, agent:)
    assignment_target = [
      team ? "Team: #{team.name}" : nil,
      agent ? "Agent: #{agent.name}" : nil
    ].compact.join(', ')

    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: "**Assignment:** #{assignment_target}\n**Reason:** #{reason}",
      private: true,
      content_attributes: {
        'aloo_assignment' => true,
        'assignment_reason' => reason,
        'assigned_team_id' => team&.id,
        'assigned_agent_id' => agent&.id
      }
    )
  end

  def build_success_message(result)
    parts = []
    parts << "Assigned to team #{result[:team].name}" if result[:team]
    parts << "Assigned to #{result[:agent].name}" if result[:agent]
    parts.join(' and ')
  end

  def track_in_context(input:, output:)
    context = Aloo::ConversationContext.find_or_create_by!(
      conversation: current_conversation,
      assistant: current_assistant
    ) do |ctx|
      ctx.context_data = {}
      ctx.tool_history = []
    end

    context.record_tool_call!(
      tool_name: 'assign',
      input: input,
      output: {
        team_assigned: output[:team_assigned],
        agent_assigned: output[:agent_assigned],
        team_id: output[:team]&.id,
        agent_id: output[:agent]&.id
      },
      success: true
    )
  end
end
