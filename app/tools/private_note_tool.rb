# frozen_string_literal: true

# Tool for adding private notes to conversations
# Used by AI agent to document observations, summaries, and important context
#
# Example usage in agent:
#   chat.with_tools([PrivateNoteTool])
#   response = chat.ask("Note: Customer mentioned they prefer email contact")
#
class PrivateNoteTool < BaseTool
  description 'Add a private note visible only to agents. Use for: ' \
              '1) Recording observations about customer sentiment or behavior, ' \
              '2) Summarizing conversation progress, ' \
              '3) Flagging potential issues or concerns, ' \
              '4) Documenting context for future reference.'

  param :content, type: :string, desc: 'The note content', required: true
  param :category, type: :string, desc: 'Note category: "observation", "summary", "warning", or "general"',
                   required: false

  VALID_CATEGORIES = %w[observation summary warning general].freeze
  CATEGORY_PREFIXES = {
    'observation' => '**Observation:**',
    'summary' => '**Summary:**',
    'warning' => '**Warning:**',
    'general' => '**Note:**'
  }.freeze

  def execute(content:, category: 'general')
    validate_context!
    category = normalize_category(category)

    if playground_mode?
      return success_response({
                                note_created: true,
                                message: '[Playground] Would add private note',
                                content: content,
                                category: category
                              })
    end

    perform_note_creation(content: content, category: category)
  rescue StandardError => e
    handle_error(content: content, category: category, error: e)
  end

  private

  def perform_note_creation(content:, category:)
    message = create_private_note(content: content, category: category)

    log_execution({ content: content, category: category }, { success: true, message_id: message.id })
    track_in_context(input: { content: content, category: category }, output: { message_id: message.id })

    success_response(note_created: true, message_id: message.id, category: category)
  end

  def handle_error(content:, category:, error:)
    log_execution({ content: content, category: category }, {}, success: false, error_message: error.message)
    error_response("Failed to add private note: #{error.message}")
  end

  def normalize_category(category)
    return 'general' if category.blank?

    normalized = category.to_s.downcase.strip
    VALID_CATEGORIES.include?(normalized) ? normalized : 'general'
  end

  def create_private_note(content:, category:)
    formatted_content = format_note_content(content: content, category: category)

    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: formatted_content,
      private: true,
      content_attributes: {
        'aloo_private_note' => true,
        'note_category' => category
      }
    )
  end

  def format_note_content(content:, category:)
    prefix = CATEGORY_PREFIXES[category] || CATEGORY_PREFIXES['general']
    "#{prefix} #{content}"
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
      tool_name: 'private_note',
      input: input,
      output: output,
      success: true
    )
  end
end
