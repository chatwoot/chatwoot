# frozen_string_literal: true

# Summarizes a conversation into a concise overview
#
# Example:
#   ConversationSummaryAgent.call(
#     conversation_messages: [{ incoming: true, content: "..." }]
#   )
#
class ConversationSummaryAgent < ApplicationAgent
  description 'Summarizes a conversation highlighting key topics, issues, status, and action items'
  model 'gpt-4.1-mini'
  temperature 0.2

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
      You are an expert conversation analyst for a customer support platform.

      Your task is to produce a concise summary of a customer support conversation.

      The summary should include:
      - The customer's main issue or request
      - Key topics discussed
      - Current status of the conversation (resolved, pending, escalated, etc.)
      - Any action items or next steps mentioned

      Guidelines:
      - Be concise but thorough — aim for 3-5 sentences
      - Use neutral, professional language
      - Focus on facts, not opinions
      - If the conversation is very short, keep the summary proportionally brief
    PROMPT
  end

  def user_prompt
    messages_text = conversation_messages.map do |msg|
      sender = msg[:incoming] || msg['incoming'] ? 'Customer' : 'Agent'
      content = msg[:content] || msg['content']
      "#{sender}: #{content}"
    end.join("\n")

    <<~PROMPT
      Please summarize the following conversation:

      #{messages_text}
    PROMPT
  end

  returns do
    string :summary, description: 'A concise summary of the conversation'
  end
end
