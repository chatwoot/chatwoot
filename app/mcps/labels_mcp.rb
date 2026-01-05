# frozen_string_literal: true

# Tool for managing conversation labels
# Used by AI agent to categorize, organize, and flag conversations
#
# Example usage in agent:
#   chat.with_tools([LabelsMcp])
#   response = chat.ask("Add labels billing and urgent to this conversation")
#
class LabelsMcp < BaseMcp
  description 'Manage conversation labels. Use for: ' \
              '1) Categorizing conversations by topic or issue type, ' \
              '2) Flagging for follow-up or escalation, ' \
              '3) Organizing conversations for reporting purposes.'

  param :action, type: :string, desc: 'Action to perform: "add", "remove", or "set"', required: true
  param :labels, type: :array, desc: 'Array of label names to apply', required: true

  VALID_ACTIONS = %w[add remove set].freeze

  def execute(action:, labels:)
    validate_context!
    action = action.to_s.downcase.strip
    labels = normalize_labels(labels)

    return invalid_action_error(action) unless valid_action?(action)
    return error_response('Labels array cannot be empty') if labels.empty?

    perform_labels_update(action: action, labels: labels)
  rescue StandardError => e
    handle_error(action: action, labels: labels, error: e)
  end

  private

  def perform_labels_update(action:, labels:)
    previous_labels = current_conversation.label_list.to_a
    perform_label_action(action: action, labels: labels)
    current_labels = current_conversation.reload.label_list.to_a

    log_and_track(action: action, labels: labels, previous_labels: previous_labels, current_labels: current_labels)
    build_success_response(action: action, labels: labels, previous_labels: previous_labels, current_labels: current_labels)
  end

  def log_and_track(action:, labels:, previous_labels:, current_labels:)
    log_execution({ action: action, labels: labels }, { success: true, previous_labels: previous_labels, current_labels: current_labels })
    track_in_context(input: { action: action, labels: labels }, output: { previous_labels: previous_labels, current_labels: current_labels })
  end

  def build_success_response(action:, labels:, previous_labels:, current_labels:)
    success_response(
      action_completed: true, action: action, labels_changed: labels,
      previous_labels: previous_labels, current_labels: current_labels
    )
  end

  def invalid_action_error(action)
    error_response("Invalid action: #{action}. Must be one of: #{VALID_ACTIONS.join(', ')}")
  end

  def handle_error(action:, labels:, error:)
    log_execution({ action: action, labels: labels }, {}, success: false, error_message: error.message)
    error_response("Failed to update labels: #{error.message}")
  end

  def valid_action?(action)
    VALID_ACTIONS.include?(action)
  end

  def normalize_labels(labels)
    Array(labels).map { |l| l.to_s.strip }.reject(&:blank?)
  end

  def perform_label_action(action:, labels:)
    case action
    when 'add'
      current_conversation.add_labels(labels)
    when 'remove'
      remove_labels(labels)
    when 'set'
      current_conversation.update_labels(labels)
    end
  end

  def remove_labels(labels_to_remove)
    current_labels = current_conversation.label_list.to_a
    updated_labels = current_labels - labels_to_remove
    current_conversation.update_labels(updated_labels)
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
      tool_name: 'labels',
      input: input,
      output: output,
      success: true
    )
  end
end
