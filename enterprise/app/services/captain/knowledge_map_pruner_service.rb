class Captain::KnowledgeMapPrunerService
  MAX_TOPICS = 15
  MAX_PROMPT_BYTES = 30_000

  def initialize(assistant:, query: nil, previous_user_message: nil)
    @assistant = assistant
    @query = query
    @previous_user_message = previous_user_message
  end

  def perform
    return {} if knowledge_map.blank?
    return full_payload if @query.nil?

    build_pruned_payload(selected_topics)
  end

  def retrieval_faq_ids
    return [] if knowledge_map.blank? || @query.blank?

    ranked_topic_names
      .first(Captain::KnowledgeMapLexicalRanker::RELEVANCE_TOPIC_COUNT)
      .filter_map { |name| topics_by_name[name] }
      .flat_map { |topic| Array(topic['faq_ids']) }
      .uniq
  end

  private

  def knowledge_map = (@knowledge_map ||= @assistant.knowledge_map)

  def topics = (@topics ||= Array(knowledge_map['topics']))

  def full_payload
    base_payload.merge('topics' => topics.map { |topic| topic_for_prompt(topic) })
  end

  def selected_topics
    selected = []

    ranked_topic_names.each do |name|
      break if selected.length >= MAX_TOPICS

      topic = topics_by_name[name]
      next unless topic

      candidate_topics = selected + [topic]
      next if JSON.generate(build_pruned_payload(candidate_topics)).bytesize > MAX_PROMPT_BYTES

      selected << topic
    end

    selected
  end

  def ranked_topic_names
    Captain::KnowledgeMapLexicalRanker.new(assistant: @assistant, topics: topics).rank(
      query: @query,
      previous_user_message: @previous_user_message
    )
  end

  def build_pruned_payload(selected)
    base_payload.merge('topics' => selected.map { |topic| topic_for_prompt(topic) })
  end

  def base_payload
    {
      'version' => knowledge_map['version'],
      'business_summary' => knowledge_map['business_summary']
    }
  end

  def topic_for_prompt(topic)
    {
      'name' => topic['name'],
      'summary' => topic['summary'],
      'concepts' => Array(topic['concepts']).first(6),
      'relationships' => Array(topic['relationships']).first(3).map do |relationship|
        relationship.slice('subject', 'predicate', 'object')
      end,
      'distinctions' => Array(topic['distinctions']).first(3).map { |distinction| distinction.slice('statement') }
    }
  end

  def topics_by_name = (@topics_by_name ||= topics.index_by { |topic| topic['name'] })
end
