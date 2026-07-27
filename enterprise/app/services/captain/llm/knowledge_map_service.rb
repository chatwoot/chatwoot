class Captain::Llm::KnowledgeMapService
  MAX_ANSWER_CHARACTERS = 10_000
  MAX_MAP_CHARACTERS = 500_000
  MAX_TOPICS = 100
  MAP_VERSION = 1
  DISCOVERY_CACHE_TTL = 24.hours

  pattr_initialize [:assistant!]

  def perform
    if empty?
      log_progress('skipped approved_faqs=0')
      return empty_result
    end

    log_progress("started approved_faqs=#{source_records.length}")

    candidates = discovery_candidates
    return empty_result if candidates.empty?

    canonical_topics = run_phase(Captain::Llm::KnowledgeMapTopicCanonicalizationService, candidates: candidates)
    topics = run_phase(
      Captain::Llm::KnowledgeMapTopicSynthesisService,
      topics: canonical_topics,
      faq_records: prompt_sources
    )
    business_summary = run_phase(Captain::Llm::KnowledgeMapBusinessSummaryService, topics: topics)
    map = assemble_map(topics, business_summary)
    log_progress("completed topics=#{topics.length} output_characters=#{JSON.generate(map).length} total_tokens=#{usage['total_tokens']}")

    { message: map, usage: usage }
  end

  def source_digest
    @source_digest ||= Digest::SHA256.hexdigest(JSON.generate(source_records))
  end

  def empty?
    source_records.empty?
  end

  def clear_discovery_checkpoint
    Redis::Alfred.delete(discovery_cache_key)
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

  def discovery_candidates
    cached_candidates = Redis::Alfred.get(discovery_cache_key)
    if cached_candidates
      candidates = JSON.parse(cached_candidates, symbolize_names: true)
      log_progress("phase=topic_discovery cache_hit items=#{candidates.length}")
      return candidates
    end

    candidates = run_phase(Captain::Llm::KnowledgeMapTopicDiscoveryService, faq_records: prompt_sources)
    Redis::Alfred.set(discovery_cache_key, JSON.generate(candidates), ex: DISCOVERY_CACHE_TTL.to_i)
    log_progress("phase=topic_discovery cached items=#{candidates.length} ttl=#{DISCOVERY_CACHE_TTL.to_i}s")
    candidates
  end

  def discovery_cache_key
    format(
      Redis::Alfred::CAPTAIN_KNOWLEDGE_MAP_DISCOVERY,
      assistant_id: assistant.id,
      source_digest: source_digest
    )
  end

  def run_phase(service_class, **attributes)
    phase = service_class.name.demodulize.delete_prefix('KnowledgeMap').delete_suffix('Service').underscore
    result = service_class.new(account: assistant.account, **attributes).perform
    raise Captain::Llm::KnowledgeMapGenerationError, result[:error] if result[:error]

    add_usage(result[:usage])
    message = result.fetch(:message)
    item_count = message.is_a?(Array) ? message.length : 1
    log_progress("phase=#{phase} completed items=#{item_count}")
    message
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

  def log_progress(message)
    Rails.logger.info("[Captain::KnowledgeMap] assistant_id=#{assistant.id} #{message}")
  end
end
