class Captain::Llm::TranslateQueryService < Captain::BaseTaskService
  MODEL = 'gpt-4.1-nano'.freeze

  pattr_initialize [:account!]

  def translate(query, target_language:)
    return query if query_in_target_language?(query)

    messages = [
      { role: 'system', content: system_prompt(target_language) },
      { role: 'user', content: query }
    ]

    response = make_api_call(model: MODEL, messages: messages)
    return query if response[:error]

    response[:message].strip
  rescue StandardError => e
    Rails.logger.warn "TranslateQueryService failed: #{e.message}, falling back to original query"
    query
  end

  private

  def event_name
    'translate_query'
  end

  def query_in_target_language?(query)
    detector = CLD3::NNetLanguageIdentifier.new(0, 1000)
    result = detector.find_language(query)

    result.reliable? && result.language == account_language_code
  rescue StandardError
    false
  end

  def account_language_code
    account.locale&.split('_')&.first
  end

  def system_prompt(target_language)
    <<~SYSTEM_PROMPT_MESSAGE
      You are a helpful assistant that translates queries from one language to another.
      Translate the query to #{target_language}.
      Return just the translated query, no other text.
    SYSTEM_PROMPT_MESSAGE
  end
end
