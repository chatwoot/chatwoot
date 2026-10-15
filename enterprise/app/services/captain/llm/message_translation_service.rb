class Captain::Llm::MessageTranslationService < Captain::BaseTaskService
  LANGUAGE_NAMES = YAML.load_file(Rails.root.join('config/languages/language_map.yml')).freeze
  # Models occasionally answer a stray "<" or "&" with a control character, which Nokogiri and Postgres reject.
  CONTROL_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/
  # A Captain that is disabled or has no key is a setup bug and must surface; a quota or model failure is for the caller to handle.
  MISCONFIGURED_CODES = [401, 403].freeze

  pattr_initialize [:account!, :texts!, :target_language!, { conversation_display_id: nil }]

  # Locales ('pt_BR'), BCP 47 tags ('zh-CN') and detected codes ('fr') all compare by their base language.
  def self.same_language?(first, second)
    first.to_s.split(/[-_]/).first == second.to_s.split(/[-_]/).first
  end

  def perform
    response = make_api_call(feature: 'message_translation', messages: messages, schema: Captain::Llm::MessageTranslationSchema)
    raise StandardError, response[:error] if MISCONFIGURED_CODES.include?(response[:error_code])
    return response if response[:error]

    response.merge(message: response[:message]['messages'].each { |item| item['text'] = item['text'].to_s.gsub(CONTROL_CHARACTERS, '') })
  end

  private

  def event_name
    'message_translation'
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: texts.to_json }
    ]
  end

  def system_prompt
    <<~SYSTEM_PROMPT_MESSAGE
      You translate messages from a customer support conversation into #{language_name}.
      The input is a JSON array of messages with "id" and "content".
      For every message return its id and its content translated into #{language_name}.
      Keep the meaning, tone and formality of the original.
      Keep markdown, line breaks, URLs, emojis, numbers, names, product terms and template variables such as {{contact.name}} exactly as they are.
      Return a message that is already written in #{language_name} unchanged.
    SYSTEM_PROMPT_MESSAGE
  end

  def language_name
    LANGUAGE_NAMES[target_language] || target_language
  end
end
