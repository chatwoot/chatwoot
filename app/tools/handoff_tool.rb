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

  def perform_handoff(reason:, priority:, summary:, preferred_team: nil) # rubocop:disable Lint/UnusedMethodArgument
    conversation = current_conversation

    # Request human assistance (flags conversation but AI continues responding)
    request_human_assistance(reason: reason, priority: priority)

    # Auto-elevate priority to high so agents see it at the top of their queues
    # (unless already urgent, in which case keep it urgent)
    effective_priority = conversation.priority == 'urgent' ? :urgent : :high

    # Update conversation priority (but NOT status - keep pending so AI continues)
    # Also don't unsnooze - only update priority for visibility
    conversation.update!(priority: effective_priority)

    # Add internal note for the human agent explaining why help was requested
    add_handoff_note(reason: reason, summary: summary, priority: priority)

    {
      human_assistance_requested: true,
      conversation_id: conversation.id,
      message: 'Human assistance requested. An agent will take over when available. AI will continue responding in the meantime.'
    }
  end

  # Flags conversation as needing human help WITHOUT stopping AI
  # Sets human_assistance_requested flag instead of aloo_handoff_active
  # AI continues responding while agents see "Help Requested" indicator
  def request_human_assistance(reason:, priority:)
    current_conversation.update!(custom_attributes: current_conversation.custom_attributes.merge(
      'human_assistance_requested' => true,
      'human_assistance_requested_at' => Time.current.iso8601,
      'human_assistance_reason' => reason,
      'human_assistance_priority' => priority
    ))
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
    parts = ["🙋 **Human Assistance Requested**\n"]
    parts << "**Priority:** #{priority.capitalize}"
    parts << "**Reason:** #{reason}"
    parts << '_AI is still responding while waiting for an agent to take over._'
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
