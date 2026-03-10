# frozen_string_literal: true

# Rewrites content based on a specified operation (improve, tone change, grammar fix, etc.)
#
# Example:
#   ContentRewriteAgent.call(
#     content: "hey can u help me with this",
#     operation: "professional",
#     conversation_messages: [{ incoming: true, content: "..." }]
#   )
#
class ContentRewriteAgent < ApplicationAgent
  description 'Rewrites content based on a specified operation'
  model 'gpt-4.1-mini'
  temperature 0.3

  on_failure do
    fallback to: ['gemini-2.5-flash', 'gpt-4.1-nano']
  end

  OPERATIONS = {
    'improve' => 'Improve this reply to be clearer, more helpful, and more professional while preserving the original meaning.',
    'fix_spelling_grammar' => 'Fix all spelling and grammar errors. Keep the original tone, style, and meaning intact.',
    'casual' => 'Rewrite in a casual, conversational tone. Keep it friendly and approachable.',
    'professional' => 'Rewrite in a professional, polished tone suitable for business communication.',
    'expand' => 'Expand this content with more detail and context while keeping it relevant and focused.',
    'shorten' => 'Make this more concise. Remove unnecessary words while preserving the key message.',
    'rephrase' => 'Rephrase this content using different words while keeping the same meaning.',
    'make_friendly' => 'Rewrite in a warm, friendly tone. Add empathy and approachability.',
    'make_formal' => 'Rewrite in a formal, respectful tone suitable for official communication.',
    'simplify' => 'Simplify the language. Use shorter sentences and simpler words.',
    'straightforward' => 'Rewrite to be direct and to the point. Remove any unnecessary qualifiers or hedging.',
    'confident' => 'Rewrite with a confident, assured tone. Be definitive and clear.',
    'friendly' => 'Rewrite in a warm, friendly tone. Add empathy and approachability.'
  }.freeze

  param :content, required: true
  param :operation, required: true
  param :conversation_messages
  param :account_id
  param :conversation_id

  def metadata
    {
      account_id: account_id&.to_s,
      conversation_id: conversation_id&.to_s,
      operation: operation
    }.compact
  end

  def system_prompt
    <<~PROMPT
      You are an expert writing assistant for a customer support platform.

      Your task is to rewrite the given content according to the specified instruction.

      Rules:
      - Return ONLY the rewritten text — no explanations, no preamble
      - Preserve the original language (if the input is in Arabic, reply in Arabic, etc.)
      - Do not add greetings or sign-offs unless the original had them
      - Keep the same general length unless the operation explicitly asks to expand or shorten
    PROMPT
  end

  def user_prompt
    instruction = OPERATIONS.fetch(operation, OPERATIONS['improve'])
    parts = ["Instruction: #{instruction}", "Content to rewrite:\n#{content}"]

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
    string :rewritten_content, description: 'The rewritten version of the content'
  end
end
