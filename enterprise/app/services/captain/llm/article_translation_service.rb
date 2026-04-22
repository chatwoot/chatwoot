class Captain::Llm::ArticleTranslationService < Captain::BaseTaskService
  pattr_initialize [:account!]

  def translate_title(title, target_language:)
    messages = [
      { role: 'system', content: title_system_prompt(target_language) },
      { role: 'user', content: title }
    ]

    response = make_api_call(model: translation_model, messages: messages)
    raise "Translation failed: #{response[:error]}" if response[:error]

    response[:message].strip
  end

  def translate_content(content, target_language:)
    messages = [
      { role: 'system', content: content_system_prompt(target_language) },
      { role: 'user', content: content }
    ]

    response = make_api_call(model: translation_model, messages: messages)
    raise "Translation failed: #{response[:error]}" if response[:error]

    response[:message].strip
  end

  private

  def event_name
    'article_translation'
  end

  def llm_credential
    @llm_credential ||= system_llm_credential
  end

  def translation_model
    @translation_model ||= InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || GPT_MODEL
  end

  def title_system_prompt(target_language)
    <<~SYSTEM_PROMPT_MESSAGE
      You are a professional translator.
      Translate the following text to #{target_language}.
      Return only the translated text, no explanations or extra formatting.
    SYSTEM_PROMPT_MESSAGE
  end

  def content_system_prompt(target_language)
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
