# frozen_string_literal: true

# Refines a previous AI-generated result based on a follow-up instruction
#
# Example:
#   FollowUpAgent.call(
#     previous_output: "Here is the rewritten text...",
#     follow_up_message: "make it shorter",
#     original_task: "rewrite",
#     conversation_messages: [{ incoming: true, content: "..." }]
#   )
#
class FollowUpAgent < ApplicationAgent
  description 'Refines a previous AI-generated result based on a follow-up instruction'
  model 'gpt-4.1-mini'
  temperature 0.3

  on_failure do
    fallback to: ['gemini-2.5-flash', 'gpt-4.1-nano']
  end

  param :previous_output, required: true
  param :follow_up_message, required: true
  param :original_task
  param :conversation_messages
  param :account_id
  param :conversation_id

  def metadata
    {
      account_id: account_id&.to_s,
      conversation_id: conversation_id&.to_s,
      original_task: original_task
    }.compact
  end

  def system_prompt
    <<~PROMPT
      You are an expert writing assistant for a customer support platform.

      You previously generated content for the user. They now want you to refine it based on their follow-up instruction.

      Rules:
      - Apply the user's requested change to the previous output
      - Return ONLY the refined text — no explanations, no preamble
      - Preserve the original language
      - If the instruction is unclear, make your best interpretation and apply it
    PROMPT
  end

  def user_prompt
    parts = [
      "Previous output:\n#{previous_output}",
      "User's refinement request: #{follow_up_message}"
    ]

    if conversation_messages.present?
      context = conversation_messages.last(10).map do |msg|
        sender = msg[:incoming] || msg['incoming'] ? 'Customer' : 'Agent'
        "#{sender}: #{msg[:content] || msg['content']}"
      end.join("\n")
      parts << "Conversation context for reference:\n#{context}"
    end

    parts.join("\n\n")
  end

  returns do
    string :refined_content, description: 'The refined version of the previous output'
  end
end
