class Captain::Llm::ConversationFaqService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  DISTANCE_THRESHOLD = 0.3
  MATCH_LIMIT = 5
  LLM_FEATURE = 'conversation_faq_generation'.freeze

  def initialize(assistant, conversation)
    super(feature: LLM_FEATURE, account: conversation.account, fallback_model: Llm::Models.default_model_for(LLM_FEATURE))
    @assistant = assistant
    @conversation = conversation
    @content = conversation_faq_content
    @embedding_service = Captain::Llm::EmbeddingService.new(account_id: conversation.account_id)
  end

  def generate_and_deduplicate
    return [] if no_human_interaction?

    generate.map { |faq| route_candidate(faq) }
  end

  private

  attr_reader :content, :conversation, :assistant, :embedding_service

  def conversation_faq_content
    [
      "Conversation ID: ##{conversation.display_id}",
      "Channel: #{conversation.inbox.channel.name}",
      'Message History:',
      conversation_faq_messages
    ].join("\n")
  end

  def conversation_faq_messages
    messages = conversation
               .messages
               .where(message_type: %i[incoming outgoing], private: false)
               .order(created_at: :asc)

    return "No messages in this conversation\n" if messages.empty?

    messages.filter_map { |message| format_conversation_faq_message(message) }.join
  end

  def format_conversation_faq_message(message)
    return unless faq_source_message?(message)

    message_content = message.content_for_llm
    return if message_content.blank?

    sender = human_support_reply?(message) ? 'Support Agent' : 'User'
    "#{sender}: #{message_content}\n"
  end

  def faq_source_message?(message)
    return true if message.incoming? && message.sender_type == 'Contact'

    human_support_reply?(message)
  end

  def human_support_reply?(message)
    return false unless message.outgoing?
    return false if message.content_attributes['automation_rule_id'].present?
    return false if message.additional_attributes['campaign_id'].present?

    message.sender_type == 'User' || message.content_attributes['external_echo'].present?
  end

  def no_human_interaction?
    conversation.first_reply_created_at.nil?
  end

  def route_candidate(faq)
    embedding = embedding_service.get_embedding(candidate_text(faq))

    if matching_record(assistant.responses.approved, faq, embedding)
      return Captain::FaqObservation.create!(
        conversation: conversation,
        generated_question: faq.fetch('question'),
        generated_answer: faq.fetch('answer'),
        status: :discarded
      )
    end

    suggestion = matching_record(assistant.faq_suggestions.open, faq, embedding)
    suggestion ||= assistant.faq_suggestions.create!(
      question: faq.fetch('question'),
      answer: faq.fetch('answer'),
      embedding: embedding
    )

    attach_observation(suggestion, faq)
  end

  def matching_record(relation, faq, embedding)
    likely_matches(relation, embedding).find { |record| same_faq?(faq, record) }
  end

  def likely_matches(relation, embedding)
    return [] unless relation.exists?

    relation
      .nearest_neighbors(:embedding, embedding, distance: 'cosine')
      .limit(MATCH_LIMIT)
      .select { |record| record.neighbor_distance < DISTANCE_THRESHOLD }
  end

  def same_faq?(candidate, existing_record)
    comparison = {
      candidate: candidate.slice('question', 'answer'),
      existing: { question: existing_record.question, answer: existing_record.answer }
    }
    prompt = Captain::Llm::ConversationFaqPromptsService.equivalence_classifier
    response = instrument_llm_call(equivalence_instrumentation_params(prompt, comparison)) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(prompt)
        .ask(comparison.to_json)
    end

    response_content = sanitize_json_response(response.content)
    return false if response_content.blank?

    JSON.parse(response_content).fetch('same_faq', false) == true
  rescue JSON::ParserError, RubyLLM::Error => e
    Rails.logger.error "FAQ equivalence classification failed: #{e.message}"
    false
  end

  def attach_observation(suggestion, faq)
    suggestion.with_lock do
      existing_observation = suggestion.observations.find_by(conversation: conversation)
      next existing_observation if existing_observation

      observation = suggestion.observations.create!(
        conversation: conversation,
        generated_question: faq.fetch('question'),
        generated_answer: faq.fetch('answer'),
        status: :attached
      )
      suggestion.update!(source_count: suggestion.source_count + 1)
      observation
    end
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
      metadata: { assistant_id: assistant.id }
    }
  end

  def equivalence_instrumentation_params(prompt, comparison)
    {
      span_name: 'llm.captain.faq_equivalence',
      model: model,
      temperature: temperature,
      account_id: conversation.account_id,
      conversation_id: conversation.display_id,
      feature_name: 'conversation_faq_deduplication',
      messages: [
        { role: 'system', content: prompt },
        { role: 'user', content: comparison.to_json }
      ],
      metadata: { assistant_id: assistant.id }
    }
  end

  def system_prompt
    account_language = conversation.account.locale_english_name
    Captain::Llm::ConversationFaqPromptsService.generator(account_language)
  end

  def parse_generation_response(response)
    return [] if response.nil?

    JSON.parse(sanitize_json_response(response)).fetch('faqs', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
