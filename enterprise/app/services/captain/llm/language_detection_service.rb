class Captain::Llm::LanguageDetectionService < Llm::BaseOpenAiService
  def detect(text)
    return nil if text.blank?

    # Truncate text to avoid token limits while still having enough content for language detection
    truncated_text = text.truncate(500)
    begin
      response = @client.chat(
        parameters: chat_parameters(truncated_text)
      )

      handle_response(response)
    rescue JSON::ParserError
      Rails.logger.error("[CAPTAIN][LanguageDetectionService] Error parsing response: #{response}")
      nil
    rescue StandardError => e
      Rails.logger.error("[CAPTAIN][LanguageDetectionService] Error detecting language: #{e.message}")
      nil
    end
  end

  private

  def chat_parameters(text)
    {
      model: @model,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: text }
      ],
      temperature: 0.2
    }
  end

  def handle_response(response)
    content = response.dig('choices', 0, 'message', 'content')&.strip
    return nil if content.blank?

    json_response = JSON.parse(content)
    json_response['language_code']
  end

  def system_prompt
    Captain::Llm::SystemPromptsService.language_detection_prompt
  end
end
