class Captain::Llm::KnowledgeMapService
  MAX_ANSWER_CHARACTERS = 10_000
  MAX_MAP_CHARACTERS = 500_000
  MAX_TOPICS = 100
  MAP_VERSION = 1

  pattr_initialize [:assistant!]

  def perform
    return empty_result if empty?

    candidates = run_phase(Captain::Llm::KnowledgeMapTopicDiscoveryService, faq_records: prompt_sources)
    return empty_result if candidates.empty?

    canonical_topics = run_phase(Captain::Llm::KnowledgeMapTopicCanonicalizationService, candidates: candidates)
    topics = run_phase(
      Captain::Llm::KnowledgeMapTopicSynthesisService,
      topics: canonical_topics,
      faq_records: prompt_sources
    )
    business_summary = run_phase(Captain::Llm::KnowledgeMapBusinessSummaryService, topics: topics)

    { message: assemble_map(topics, business_summary), usage: usage }
  end

  def source_digest
    @source_digest ||= Digest::SHA256.hexdigest(JSON.generate(source_records))
  end

  def empty?
    source_records.empty?
  end

  private

  def source_records
    @source_records ||= assistant.responses.approved.order(:id).pluck(:id, :question, :answer).map do |id, question, answer|
      { id: id, question: question, answer: answer }
    end
  end

  def prompt_sources
    @prompt_sources ||= source_records.map do |source|
      source.merge(answer: source[:answer].to_s.first(MAX_ANSWER_CHARACTERS))
    end
  end

  def run_phase(service_class, **attributes)
    result = service_class.new(account: assistant.account, **attributes).perform
    raise Captain::Llm::KnowledgeMapGenerationError, result[:error] if result[:error]

    add_usage(result[:usage])
    result.fetch(:message)
  end

  def assemble_map(topics, business_summary)
    sorted_topics = topics.sort_by { |topic| topic[:name].downcase }
    raise Captain::Llm::KnowledgeMapGenerationError, "Knowledge map exceeds #{MAX_TOPICS} topics" if sorted_topics.length > MAX_TOPICS

    map = {
      version: MAP_VERSION,
      business_summary: business_summary[:business_summary],
      business_summary_faq_ids: business_summary[:business_summary_faq_ids],
      topics: sorted_topics
    }.deep_stringify_keys
    raise Captain::Llm::KnowledgeMapGenerationError, 'Knowledge map exceeds the size limit' if JSON.generate(map).length > MAX_MAP_CHARACTERS

    map
  end

  def add_usage(phase_usage)
    usage.each_key { |key| usage[key] += phase_usage&.dig(key).to_i }
  end

  def usage
    @usage ||= %w[prompt_tokens completion_tokens total_tokens].index_with { 0 }
  end

  def empty_result
    { message: {}, usage: usage }
  end
end
