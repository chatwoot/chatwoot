class Captain::Llm::MessageTranslationService < Captain::BaseTaskService
  LANGUAGE_NAMES = YAML.load_file(Rails.root.join('config/languages/language_map.yml')).freeze
  # Models occasionally answer a stray "<" or "&" with a control character, which Postgres rejects in jsonb.
  CONTROL_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/

  pattr_initialize [:account!, :texts!, :target_language!, { conversation_display_id: nil }]

  # Locales ('pt_BR'), BCP 47 tags ('zh-CN') and detected codes ('fr') all compare by their base language.
  def self.same_language?(first, second)
    first.to_s.split(/[-_]/).first == second.to_s.split(/[-_]/).first
  end

  def perform
    response = make_api_call(feature: 'message_translation', messages: messages, schema: Captain::Llm::MessageTranslationSchema)
    return response if response[:error]

    response.merge(message: response[:message]['translations'].map { |text| text.to_s.gsub(CONTROL_CHARACTERS, '') })
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
      The input is a JSON array of texts. Return one translation per text, in the same order.
      Keep the meaning, tone and formality of the original.
      Keep markdown, line breaks, URLs, emojis, numbers, names, product terms and template variables such as {{contact.name}} exactly as they are.
      Return a text that is already written in #{language_name} unchanged.
    SYSTEM_PROMPT_MESSAGE
  end

  # Locales and tags share the map: 'pt-BR' and 'pt_BR' are both Portuguese (Brazil).
  def language_name
    LANGUAGE_NAMES[target_language.to_s.tr('-', '_')] || target_language
  end
end
