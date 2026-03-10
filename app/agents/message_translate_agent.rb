# frozen_string_literal: true

# Translates message content to a target language
#
# Example:
#   MessageTranslateAgent.call(
#     content: "How can I help you?",
#     target_language: "ar"
#   )
#
class MessageTranslateAgent < ApplicationAgent
  description 'Translates message content to a target language'
  model 'gpt-4.1-mini'
  temperature 0.1

  on_failure do
    fallback to: ['gemini-2.5-flash', 'gpt-4.1-nano']
  end

  param :content, required: true
  param :target_language, required: true
  param :account_id
  param :message_id

  def metadata
    {
      account_id: account_id&.to_s,
      message_id: message_id&.to_s,
      target_language: target_language
    }.compact
  end

  def system_prompt
    <<~PROMPT
      You are a professional translator for a customer support platform.

      Rules:
      - Translate the content accurately to the target language
      - Preserve the original formatting (line breaks, lists, etc.)
      - Preserve HTML tags if present — translate only the text content within them
      - Do not add, remove, or alter any information
      - Do not add explanations or notes — return ONLY the translation
      - If the content is already in the target language, return it unchanged
      - Maintain the same tone and register as the original
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Target language: #{target_language}

      Content to translate:
      #{content}
    PROMPT
  end

  returns do
    string :translated_text, description: 'The translated content'
  end
end
