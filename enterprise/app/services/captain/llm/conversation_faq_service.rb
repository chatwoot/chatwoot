class Captain::Llm::ConversationFaqService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  DISTANCE_THRESHOLD = 0.3
  MATCH_LIMIT = 5
  LLM_FEATURE = 'conversation_faq_generation'.freeze

  def initialize(assistant, conversation)
    super(feature: LLM_FEATURE, account: conversation.account, fallback_model: Llm::Models.default_model_for(LLM_FEATURE))
    @assistant = assistant
    @conversation = conversation
    @content = Captain::Llm::ConversationFaqContentService.new(assistant, conversation).generate
    @embedding_service = Captain::Llm::EmbeddingService.new(account_id: conversation.account_id)
  end

  def generate_suggestions
    return [] if no_human_interaction?

    generate.map { |faq| route_candidate(faq) }
  end

  private

  attr_reader :content, :conversation, :assistant, :embedding_service

  def no_human_interaction?
    conversation.first_reply_created_at.nil?
  end

  def route_candidate(faq)
    embedding = embedding_service.get_embedding(candidate_text(faq))

    return discard_observation(faq) if matching_record(approved_faqs_for_language, faq, embedding)
    return discard_observation(faq) if matching_record(dismissed_suggestions_for_language, faq, embedding)

    suggestion = matching_record(open_suggestions_for_language, faq, embedding)
    suggestion ||= assistant.faq_suggestions.create!(
      question: faq.fetch('question'),
      answer: faq.fetch('answer'),
      embedding: embedding,
      language: faq_language
    )

    attach_observation(suggestion, faq)
  end

  def matching_record(relation, faq, embedding)
    likely_matches(relation, embedding).find { |record| same_faq?(faq, record) }
  end

  def likely_matches(relation, embedding)
    return [] unless relation.exists?

    ApplicationRecord.transaction do
      # Force an exact search because IVFFlat can miss matches after relation filters.
      # SET LOCAL keeps the planner change scoped to this transaction.
      ApplicationRecord.connection.execute('SET LOCAL enable_indexscan = off')
      relation
        .nearest_neighbors(:embedding, embedding, distance: 'cosine')
        .limit(MATCH_LIMIT)
        .select { |record| record.neighbor_distance < DISTANCE_THRESHOLD }
    end
  end

  def same_faq?(candidate, existing_record)
    comparison = {
      candidate: candidate.slice('question', 'answer'),
      existing: { question: existing_record.question, answer: existing_record.answer }
    }
    prompt = Captain::Llm::ConversationFaqPromptsService.same_faq
    response = instrument_llm_call(match_instrumentation_params(prompt, comparison)) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(prompt)
        .ask(comparison.to_json)
    end

    response_content = sanitize_json_response(response.content)
    return false if response_content.blank?

    JSON.parse(response_content).fetch('same_faq', false) == true
  rescue JSON::ParserError, RubyLLM::Error => e
    Rails.logger.error "FAQ match failed: #{e.message}"
    false
  end

  def attach_observation(suggestion, faq)
    suggestion.with_lock do
      next unless suggestion.open?

      existing_observation = suggestion.observations.find_by(conversation: conversation)
      next existing_observation if existing_observation

      observation = suggestion.observations.create!(
        conversation: conversation,
        generated_question: faq.fetch('question'),
        generated_answer: faq.fetch('answer'),
        language: faq_language,
        status: :attached
      )
      suggestion.update!(source_count: suggestion.source_count + 1)
      observation
    end
  end

  def discard_observation(faq)
    Captain::FaqObservation.find_or_create_by!(
      conversation: conversation,
      generated_question: faq.fetch('question'),
      generated_answer: faq.fetch('answer'),
      language: faq_language,
      status: :discarded
    )
  end

  def open_suggestions_for_language
    assistant.faq_suggestions.where(account_id: conversation.account_id).open.by_language(faq_language)
  end

  def dismissed_suggestions_for_language
    assistant.faq_suggestions.where(account_id: conversation.account_id).dismissed.by_language(faq_language)
  end

  def approved_faqs_for_language
    return assistant.responses.approved if faq_language == account_language

    assistant.responses.none
  end

  def candidate_text(faq)
    "#{faq.fetch('question')}: #{faq.fetch('answer')}"
  end

  def generate
    response = instrument_llm_call(generation_instrumentation_params) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(content)
    end
    parse_generation_response(response.content)
  rescue RubyLLM::Error => e
    Rails.logger.error "LLM API Error: #{e.message}"
    []
  end

  def generation_instrumentation_params
    {
      span_name: 'llm.captain.conversation_faq',
      model: model,
      temperature: temperature,
      account_id: conversation.account_id,
      conversation_id: conversation.display_id,
      feature_name: 'conversation_faq',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: content }
      ],
      metadata: { assistant_id: assistant.id, language: faq_language }
    }
  end

  def match_instrumentation_params(prompt, comparison)
    {
      span_name: 'llm.captain.faq_match',
      model: model,
      temperature: temperature,
      account_id: conversation.account_id,
      conversation_id: conversation.display_id,
      feature_name: 'conversation_faq_match',
      messages: [
        { role: 'system', content: prompt },
        { role: 'user', content: comparison.to_json }
      ],
      metadata: { assistant_id: assistant.id, language: faq_language }
    }
  end

  def system_prompt
    Captain::Llm::ConversationFaqPromptsService.generator(language_name(faq_language))
  end

  def faq_language
    @faq_language ||= normalize_language(conversation.language.presence || conversation.account.locale.presence || I18n.default_locale.to_s)
  end

  def account_language
    @account_language ||= normalize_language(conversation.account.locale.presence || I18n.default_locale.to_s)
  end

  def normalize_language(language)
    language.to_s.tr('-', '_').split('_').first.downcase
  end

  def language_name(language)
    ISO_639.find(language)&.english_name&.downcase || 'english'
  end

  def parse_generation_response(response)
    return [] if response.nil?

    JSON.parse(sanitize_json_response(response)).fetch('faqs', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
