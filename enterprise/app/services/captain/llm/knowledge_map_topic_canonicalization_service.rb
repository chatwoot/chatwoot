class Captain::Llm::KnowledgeMapTopicCanonicalizationService < Captain::Llm::KnowledgeMapBaseService
  MAX_TOPICS = 100
  MAX_CANDIDATES_PER_CALL = 50

  pattr_initialize [:account!, :candidates!]

  def perform
    canonical_topics = candidates.one? ? candidates : canonicalize
    { message: canonical_topics, usage: usage }
  end

  private

  def canonicalize
    current_candidates = candidates

    loop do
      batches = candidate_batches(current_candidates)
      maximum_topics = batches.many? ? (MAX_TOPICS.to_f / batches.length).ceil : MAX_TOPICS
      candidates_by_id = current_candidates.index_by { |item| item[:candidate_id] }
      canonicalized = batches.flat_map { |batch| canonicalize_batch(batch, candidates_by_id, maximum_topics) }
      canonicalized = merge_duplicate_topics(canonicalized)
      return canonicalized if canonicalized.length <= MAX_TOPICS
      raise Captain::Llm::KnowledgeMapGenerationError, 'Topic canonicalization made no progress' if canonicalized.length >= current_candidates.length

      current_candidates = canonicalized
    end
  end

  def candidate_batches(current_candidates)
    cards = current_candidates.map { |candidate| candidate.slice(:candidate_id, :name, :summary, :concepts) }
    max_items = MAX_CANDIDATES_PER_CALL if current_candidates.length > MAX_TOPICS
    chunked(cards, max_items: max_items)
  end

  def canonicalize_batch(batch, candidates_by_id, maximum_topics)
    message = generate(
      schema: Captain::Llm::KnowledgeMapTopicCanonicalizationSchema,
      system_prompt: system_prompt,
      payload: { topic_candidates: batch, maximum_topics: maximum_topics }
    )
    topics = normalize_topics(message['topics'])
    topics = reconcile_coverage(topics, batch, candidates_by_id)
    topics.map { |topic| expand_topic(topic, candidates_by_id) }
  end

  def normalize_topics(raw_topics)
    Array(raw_topics).filter_map do |raw_topic|
      topic = raw_topic.to_h.deep_symbolize_keys
      name = clean_string(topic[:name], 100)
      summary = clean_string(topic[:summary], 300)
      candidate_ids = clean_strings(topic[:candidate_ids], limit: 1000, length: 100)
      next if name.blank? || summary.blank? || candidate_ids.empty?

      {
        name: name,
        summary: summary,
        concepts: clean_strings(topic[:concepts], limit: 12, length: 100),
        candidate_ids: candidate_ids
      }
    end
  end

  def reconcile_coverage(topics, batch, candidates_by_id)
    allowed_ids = batch.pluck(:candidate_id)
    assigned_ids = []
    reconciled_topics = topics.filter_map do |topic|
      candidate_ids = topic[:candidate_ids].select { |candidate_id| allowed_ids.include?(candidate_id) && assigned_ids.exclude?(candidate_id) }
      next if candidate_ids.empty?

      assigned_ids.concat(candidate_ids)
      topic.merge(candidate_ids: candidate_ids)
    end

    missing_topics = (allowed_ids - assigned_ids).map do |candidate_id|
      candidate = candidates_by_id.fetch(candidate_id)
      candidate.slice(:name, :summary, :concepts).merge(candidate_ids: [candidate_id])
    end
    reconciled_topics + missing_topics
  end

  def expand_topic(topic, candidates_by_id)
    members = topic[:candidate_ids].filter_map { |candidate_id| candidates_by_id[candidate_id] }
    topic.merge(
      candidate_id: next_candidate_id,
      member_ids: members.flat_map { |member| member[:member_ids] }.uniq,
      faq_ids: normalize_ids(members.flat_map { |member| member[:faq_ids] })
    )
  end

  def merge_duplicate_topics(topics)
    topics.group_by { |topic| topic[:name].downcase }.values.map do |duplicates|
      primary = duplicates.first
      primary.merge(
        summary: duplicates.max_by { |topic| topic[:summary].length }[:summary],
        concepts: unique_strings(duplicates.flat_map { |topic| topic[:concepts] }).first(12),
        member_ids: duplicates.flat_map { |topic| topic[:member_ids] }.uniq,
        faq_ids: normalize_ids(duplicates.flat_map { |topic| topic[:faq_ids] })
      )
    end
  end

  def next_candidate_id
    @candidate_sequence = @candidate_sequence.to_i + 1
    "canonical_#{@candidate_sequence}"
  end

  def system_prompt
    <<~PROMPT
      Canonicalize a set of product topic candidates into a coherent topic inventory.
      Every candidate_id must appear exactly once in the output. Never omit, duplicate, or invent candidate IDs.

      Merge aliases, duplicates, and overly narrow subtopics under stable product-domain names. Keep meaningfully
      different domains separate. Preserve enough topics to represent the supplied product accurately; the
      maximum_topics value is a safety ceiling, not a target. Never return more than maximum_topics.
      Use only the supplied candidate content.
    PROMPT
  end

  def event_name
    'knowledge_map_topic_canonicalization'
  end
end
