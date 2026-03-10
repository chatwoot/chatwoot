# frozen_string_literal: true

# Suggests a reply to a customer based on conversation history
#
# Example:
#   ReplySuggestionAgent.call(
#     conversation_messages: [{ incoming: true, content: "..." }]
#   )
#
class ReplySuggestionAgent < ApplicationAgent
  description 'Suggests a reply to the customer based on conversation context'
  model 'gpt-4.1-mini'
  temperature 0.4

  on_failure do
    fallback to: ['gemini-2.5-flash', 'gpt-4.1-nano']
  end

  param :conversation_messages, required: true
  param :account_id
  param :conversation_id

  def metadata
    {
      account_id: account_id&.to_s,
      conversation_id: conversation_id&.to_s,
      message_count: conversation_messages&.size&.to_s
    }.compact
  end

  def system_prompt
    <<~PROMPT
      You are a helpful customer support agent drafting a reply to a customer.

      Your task is to analyze the conversation and draft a professional, helpful reply that:
      - Directly addresses the customer's most recent message or concern
      - Is clear, concise, and empathetic
      - Provides actionable next steps when applicable
      - Maintains a professional yet friendly tone
      - Does not make up information — if unsure, suggest the agent verify before sending

      Guidelines:
      - Keep the reply focused and to the point
      - Use the same language the customer is writing in
      - Do not include greetings like "Dear customer" — start with the substance
      - Do not include sign-offs or signatures
    PROMPT
  end

  def user_prompt
    messages_text = conversation_messages.map do |msg|
      sender = msg[:incoming] || msg['incoming'] ? 'Customer' : 'Agent'
      content = msg[:content] || msg['content']
      "#{sender}: #{content}"
    end.join("\n")

    <<~PROMPT
      Based on the following conversation, draft a reply to the customer:

      #{messages_text}
    PROMPT
  end

  returns do
    string :reply, description: 'A suggested reply to the customer'
  end
end
