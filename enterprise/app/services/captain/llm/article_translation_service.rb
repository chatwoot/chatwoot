class Captain::Llm::ArticleTranslationService < Captain::BaseTaskService
  TYPES = %i[title content].freeze

  pattr_initialize [:account!, :text!, :target_language!, :type!]

  def perform
    raise ArgumentError, "Invalid type: #{type}" unless TYPES.include?(type)

    response = make_api_call(model: translation_model, messages: messages)
    return response if response[:error]

    response.merge(message: response[:message].strip)
  end

  private

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: text }
    ]
  end

  def system_prompt
    type == :title ? title_system_prompt : content_system_prompt
  end

  def event_name
    'article_translation'
  end

  def llm_credential
    @llm_credential ||= system_llm_credential
  end

  def translation_model
    @translation_model ||= InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || GPT_MODEL
  end

  def title_system_prompt
    <<~SYSTEM_PROMPT_MESSAGE
      You are a professional translator.
      Translate the following text to #{target_language}.
      Return only the translated text, no explanations or extra formatting.
    SYSTEM_PROMPT_MESSAGE
  end

  def content_system_prompt
    <<~SYSTEM_PROMPT_MESSAGE
      You are a professional translator. Translate the following content to #{target_language}.
      The content is markdown that may contain embedded HTML blocks.
      Rules:
      - Translate ONLY the visible text content (headings, paragraphs, list items, table cells, etc.).
      - Preserve ALL markdown formatting exactly: headings (#), bold (**), italic (*), links, lists, code blocks, blockquotes, tables, horizontal rules.
      - Preserve ALL HTML tags, attributes, and structure exactly as they are.
      - Do NOT translate or modify: URLs, image src/alt attributes, link href values, class names, IDs, data attributes, code blocks, or any HTML attribute values.
      - Keep all image tags (both markdown ![](url) and HTML <img>), iframes, and embedded media completely unchanged.
      - Preserve all line breaks, blank lines, and whitespace patterns.
      - Return ONLY the translated content, no wrapping or explanations.
    SYSTEM_PROMPT_MESSAGE
  end
end
