class Captain::Llm::LanguageDetectionService < Captain::BaseTaskService
  # A greeting or a thank-you alone neither sets the thread language nor is worth a model call.
  MIN_TEXT_BYTES = 10

  pattr_initialize [:account!, :text!]

  def perform
    return {} if text.to_s.bytesize < MIN_TEXT_BYTES

    make_api_call(feature: 'language_detection', messages: messages, schema: Captain::Llm::LanguageDetectionSchema)
  end

  # The code of the language the text is written in, or nil when it cannot be told.
  def language
    response = perform
    Rails.logger.warn("[AutoTranslate] language detection failed: #{response[:error]}") if response[:error]
    code = response.dig(:message, 'language')
    code unless code.blank? || code == 'und'
  end

  private

  def event_name
    'language_detection'
  end

  # Runs on every inbound message before anyone reads the thread, like the help center query translation:
  # a two-letter answer from a nano model is not a Captain response.
  def counts_toward_usage?
    false
  end

  # Two letters about one line of text: the default reasoning effort of the gpt-5 models adds seconds for nothing.
  def build_chat(...)
    super.with_thinking(effort: :minimal)
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: text }
    ]
  end

  def system_prompt
    <<~SYSTEM_PROMPT_MESSAGE
      You identify the language a customer support message is written in.
      Return its ISO 639-1 code, such as en, de or pt. Romanized text counts as its language, so Hinglish is hi.
      Return und when the text is too short or ambiguous to tell, such as a name, a number, an emoji or a single word that exists in several languages.
    SYSTEM_PROMPT_MESSAGE
  end
end
