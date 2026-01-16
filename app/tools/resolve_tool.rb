# frozen_string_literal: true

# Tool for resolving conversations
# Used by AI agent to mark conversations as resolved when the issue is addressed
#
# Example usage in agent:
#   chat.with_tools([ResolveTool])
#   response = chat.ask("The customer's question has been answered, resolve the conversation")
#
class ResolveTool < BaseTool
  description 'Resolve this conversation. Use when: ' \
              '1) The customer issue has been fully addressed, ' \
              '2) The customer confirms their question is answered, ' \
              '3) No further action is needed from customer service.'

  param :reason, type: :string, desc: 'Brief explanation of why the conversation is being resolved', required: true
  param :summary, type: :string, desc: 'Summary of the conversation for future reference', required: false

  def execute(reason:, summary: nil)
    validate_context!

    if playground_mode?
      return success_response({
                                resolved: true,
                                message: '[Playground] Would resolve conversation',
                                reason: reason
                              })
    end

    return error_response('Conversation is already resolved') if current_conversation.resolved?

    perform_resolution(reason: reason, summary: summary)
  rescue StandardError => e
    handle_error(reason: reason, error: e)
  end

  private

  def perform_resolution(reason:, summary:)
    add_summary_note(summary) if summary.present?
    add_resolution_activity(reason)
    current_conversation.resolved!

    success_response(resolved: true, conversation_id: current_conversation.id, reason: reason, message: 'Conversation has been resolved')
  end

  def handle_error(reason:, error:)
    error_response("Failed to resolve conversation: #{error.message}")
  end

  def add_summary_note(summary)
    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: "**Conversation Summary:** #{summary}",
      private: true,
      content_attributes: {
        'aloo_resolution_summary' => true
      }
    )
  end

  def add_resolution_activity(reason)
    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: "Conversation resolved by AI: #{reason}",
      private: false,
      content_attributes: {
        'aloo_resolved' => true,
        'resolution_reason' => reason
      }
    )
  end
end
