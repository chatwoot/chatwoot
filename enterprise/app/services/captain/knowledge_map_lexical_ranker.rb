class Captain::KnowledgeMapLexicalRanker
  FAQ_WEIGHT = 5.0
  HISTORY_WEIGHT = 0.3
  RELEVANCE_TOPIC_COUNT = 5
  QUERY_COVERAGE_WEIGHT = 0.8
  QUERY_REDUNDANCY_WEIGHT = 0.15
  TOPIC_REDUNDANCY_WEIGHT = 0.25

  METADATA_WEIGHTS = { 'name' => 8.0, 'concepts' => 5.0, 'distinctions' => 3.0, 'relationships' => 2.0, 'summary' => 1.5 }.freeze

  STOP_WORDS = %w[
    a an and are as at be been but by can chatwoot correct could create did do does for from had happen
    has have how i if in into is it its me my of older on one or other our perform return several should
    show some that the their them then there these they this those to two use using via was we what when
    where which while who why will with work would you your
  ].index_with(true).freeze

  HISTORY_REFERENCE_PATTERN = /\b(it|same|that|these|this|those|value)\b/i

  def initialize(assistant:, topics:)
    @assistant = assistant
    @topics = topics
  end

  def rank(query:, previous_user_message: nil)
    query_document = build_document(query)
    previous_document = build_document(previous_user_message)
    ranking_document = query_document
    ranking_document = combine_documents(query_document, previous_document) if use_previous_user_message?(query, previous_user_message)

    scored_topics = search_index['topics'].filter_map do |topic|
      score = topic_score(query_document, topic)
      score += topic_score(previous_document, topic) * HISTORY_WEIGHT if use_previous_user_message?(query, previous_user_message)
      topic.merge('score' => score) if score.positive?
    end

    diversify(scored_topics, ranking_document).pluck('name')
  end

  private

  def diversify(scored_topics, query_document)
    remaining = scored_topics.sort_by { |topic| [-topic['score'], topic['name']] }
    selected = remaining.shift(RELEVANCE_TOPIC_COUNT)
    covered_query_tokens = selected.flat_map { |topic| matched_query_tokens(topic, query_document) }.to_set
    maximum_score = scored_topics.pluck('score').max.to_f

    until remaining.empty?
      next_topic = remaining.min_by do |topic|
        [-diversity_score(topic, selected, covered_query_tokens, query_document, maximum_score), -topic['score'], topic['name']]
      end

      selected << next_topic
      covered_query_tokens.merge(matched_query_tokens(next_topic, query_document))
      remaining.delete(next_topic)
    end

    selected
  end

  def diversity_score(topic, selected, covered_query_tokens, query_document, maximum_score)
    relevance_score = topic['score'] / maximum_score
    relevance_score +
      query_coverage_score(topic, covered_query_tokens, query_document) -
      redundancy_penalty(topic, selected, covered_query_tokens, query_document)
  end

  def query_coverage_score(topic, covered_query_tokens, query_document)
    uncovered_tokens = matched_query_tokens(topic, query_document) - covered_query_tokens.to_a
    uncovered_tokens.length.to_f / query_document['tokens'].length * QUERY_COVERAGE_WEIGHT
  end

  def redundancy_penalty(topic, selected, covered_query_tokens, query_document)
    matched_tokens = matched_query_tokens(topic, query_document)
    uncovered_token_count = (matched_tokens - covered_query_tokens.to_a).length
    query_redundancy = matched_tokens.empty? ? 0.0 : 1 - (uncovered_token_count.to_f / matched_tokens.length)
    topic_redundancy = selected.map { |selected_topic| token_overlap(topic, selected_topic) }.max.to_f

    (query_redundancy * QUERY_REDUNDANCY_WEIGHT) + (topic_redundancy * TOPIC_REDUNDANCY_WEIGHT)
  end

  def matched_query_tokens(topic, query_document) = query_document['tokens'].keys.select { |token| topic['search_document']['tokens'].key?(token) }

  def token_overlap(left_topic, right_topic)
    left_tokens = left_topic['metadata_document']['tokens'].keys
    right_tokens = right_topic['metadata_document']['tokens'].keys
    return 0.0 if left_tokens.empty? || right_tokens.empty?

    (left_tokens & right_tokens).length.to_f / [left_tokens.length, right_tokens.length].min
  end

  def topic_score(query_document, topic)
    metadata_score = METADATA_WEIGHTS.sum do |field, weight|
      weight * similarity(query_document, topic['metadata'].fetch(field), search_index['topic_idf'], phrase_weight: 0.5)
    end

    faq_score = topic['faq_documents'].map do |document|
      similarity(query_document, document, search_index['faq_idf'], phrase_weight: 1.25)
    end.max.to_f

    metadata_score + (faq_score * FAQ_WEIGHT)
  end

  def similarity(query_document, target_document, idf, phrase_weight:)
    query_tokens = query_document['tokens']
    return 0.0 if query_tokens.empty?

    matched_tokens = query_tokens.keys.select { |token| target_document['tokens'].key?(token) }
    return 0.0 if matched_tokens.empty?

    score = matched_tokens.sum { |token| idf.fetch(token) }
    score += phrase_score(query_document, target_document, idf) * phrase_weight
    score * (1 + (matched_tokens.length.to_f / query_tokens.length))
  end

  def phrase_score(query_document, target_document, idf)
    query_document['bigrams'].sum do |bigram, (left, right)|
      next 0.0 unless target_document['bigrams'].key?(bigram)

      (idf.fetch(left) + idf.fetch(right)) / 2
    end
  end

  def use_previous_user_message?(query, previous_user_message)
    previous_user_message.present? && query.to_s.match?(HISTORY_REFERENCE_PATTERN)
  end

  def search_index
    @search_index ||= Rails.cache.fetch(search_index_cache_key, expires_in: 24.hours) { build_search_index }
  end

  def search_index_cache_key = "captain/knowledge-map-lexical-ranker/v3/#{@assistant.cache_key_with_version}"

  def build_search_index
    faq_documents = faq_questions.transform_values { |question| build_document(question) }
    indexed_topics = @topics.map do |topic|
      metadata = METADATA_WEIGHTS.keys.index_with { |field| build_document(topic_field_text(topic, field)) }
      topic_faq_documents = Array(topic['faq_ids']).filter_map { |faq_id| faq_documents[faq_id] }
      metadata_document = combine_documents(*metadata.values)

      {
        'name' => topic['name'],
        'metadata' => metadata,
        'metadata_document' => metadata_document,
        'faq_documents' => topic_faq_documents,
        'search_document' => combine_documents(metadata_document, *topic_faq_documents)
      }
    end

    {
      'topics' => indexed_topics,
      'topic_idf' => inverse_document_frequency(indexed_topics.pluck('metadata_document')),
      'faq_idf' => inverse_document_frequency(faq_documents.values)
    }
  end

  def faq_questions
    faq_ids = @topics.flat_map { |topic| Array(topic['faq_ids']) }.uniq
    @assistant.responses.approved.where(id: faq_ids).pluck(:id, :question).to_h
  end

  def topic_field_text(topic, field)
    return Array(topic[field]).join(' ') if field == 'concepts'
    return Array(topic[field]).filter_map { |item| item['statement'] }.join(' ') if field == 'distinctions'

    if field == 'relationships'
      return Array(topic[field])
             .map { |item| item.slice('subject', 'predicate', 'object').values.join(' ') }
             .join(' ')
    end

    topic[field].to_s
  end

  def combine_documents(*documents)
    tokens = documents.flat_map { |document| document['tokens'].keys }.uniq
    bigrams = documents.each_with_object({}) { |document, result| result.merge!(document['bigrams'] || {}) }
    { 'tokens' => tokens.index_with(true), 'bigrams' => bigrams }
  end

  def inverse_document_frequency(documents)
    document_frequency = Hash.new(0)
    documents.each do |document|
      document['tokens'].each_key { |token| document_frequency[token] += 1 }
    end

    document_count = documents.length
    document_frequency.transform_values do |frequency|
      Math.log(1 + ((document_count - frequency + 0.5) / (frequency + 0.5)))
    end
  end

  def build_document(text)
    tokens = tokenize(text)
    {
      'tokens' => tokens.index_with(true),
      'bigrams' => tokens.each_cons(2).to_h { |left, right| ["#{left} #{right}", [left, right]] }
    }
  end

  def tokenize(text)
    text.to_s
        .gsub(/\btime[\s_-]+zones?\b/i, 'timezone')
        .gsub(/([a-z0-9])([A-Z])/, '\1 \2')
        .downcase
        .scan(/[a-z0-9]+/)
        .filter_map { |token| normalized_token(token) }
  end

  def normalized_token(token)
    normalized = case token
                 when /\A.{3,}ies\z/ then "#{token.delete_suffix('ies')}y"
                 when /\A.{2,}(?:ches|shes|xes|zes)\z/ then token.delete_suffix('es')
                 when /\A.{4,}(?<!s)s\z/ then token.delete_suffix('s')
                 else token
                 end
    return if normalized.length < 2 || STOP_WORDS.key?(normalized)

    normalized
  end
end
