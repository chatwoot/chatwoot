# frozen_string_literal: true

# Tool for executing macros on conversations
# Used by AI agent to trigger predefined workflows
#
# Example usage in agent:
#   chat.with_tools([ExecuteMacroTool])
#   response = chat.ask("The customer wants to know about shipping, trigger the shipping info macro")
#
class ExecuteMacroTool < BaseTool
  description 'Execute a predefined macro/workflow on the current conversation. ' \
              'Macros are preconfigured action sequences that can send messages, add labels, ' \
              'assign teams, change status, and more. Use when a macro matches the customer need.'

  param :macro_id, type: :integer, desc: 'The ID of the macro to execute', required: true
  param :reason, type: :string, desc: 'Brief explanation of why this macro is being triggered', required: false

  def execute(macro_id:, reason: nil)
    validate_context!

    macro = find_macro(macro_id)
    return error_response('Macro not found or not available for AI use') unless macro

    if playground_mode?
      return success_response({
                                message: '[Playground] Would execute macro',
                                macro_id: macro.id,
                                macro_name: macro.name,
                                reason: reason
                              })
    end

    perform_execution(macro: macro, reason: reason)
  rescue StandardError => e
    handle_error(macro_id: macro_id, error: e)
  end

  private

  def find_macro(macro_id)
    current_account.macros.ai_available.find_by(id: macro_id)
  end

  def perform_execution(macro:, reason:)
    add_execution_note(macro: macro, reason: reason) if reason.present?
    execute_macro(macro)

    success_response({
                       executed: true,
                       macro_id: macro.id,
                       macro_name: macro.name,
                       message: "Successfully executed macro: #{macro.name}"
                     })
  end

  def handle_error(macro_id:, error:)
    error_response("Failed to execute macro #{macro_id}: #{error.message}")
  end

  def execute_macro(macro)
    ::Macros::ExecutionService.new(macro, current_conversation, execution_user).perform
  end

  def execution_user
    # Use an administrator as the acting user for macro execution
    # This is needed for audit trail and actions that require a user context
    current_account.administrators.first
  end

  def add_execution_note(macro:, reason:)
    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: "AI triggered macro \"#{macro.name}\": #{reason}",
      private: true,
      content_attributes: {
        'aloo_macro_executed' => true,
        'macro_id' => macro.id,
        'macro_name' => macro.name
      }
    )
  end
end
