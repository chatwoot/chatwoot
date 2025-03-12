class Captain::Llm::LanguageDetectionService < Llm::BaseOpenAiService
  def detect(text)
    return nil if text.blank?

    # Truncate text to avoid token limits while still having enough content for language detection
    truncated_text = text.truncate(500)

    response = @client.chat(
      parameters: {
        model: @model,
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: truncated_text }
        ],
        temperature: 0.2
      }
    )

    language = response.dig('choices', 0, 'message', 'content')&.strip
    return nil if language.blank?

    # Clean up the response to ensure it's just the language name
    language.gsub(/^["']|["']$/, '').gsub(/^Language: /, '').strip
  rescue StandardError => e
    Rails.logger.error("[CAPTAIN][LanguageDetectionService] Error detecting language: #{e.message}")
    nil
  end

  private

  def system_prompt
    Captain::Llm::SystemPromptsService.language_detection_prompt
  end
end
