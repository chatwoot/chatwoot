class Captain::KnowledgeMapLexicalRanker
  FAQ_WEIGHT = 5.0
  HISTORY_WEIGHT = 0.3

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

    scores = search_index['topics'].filter_map do |topic|
      score = topic_score(query_document, topic)
      score += topic_score(previous_document, topic) * HISTORY_WEIGHT if use_previous_user_message?(query, previous_user_message)
      [topic['name'], score] if score.positive?
    end

    scores.sort_by { |name, score| [-score, name] }.map(&:first)
  end

  private

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

  def search_index_cache_key
    "captain/knowledge-map-lexical-ranker/v1/#{@assistant.cache_key_with_version}"
  end

  def build_search_index
    faq_documents = faq_questions.transform_values { |question| build_document(question) }
    indexed_topics = @topics.map do |topic|
      {
        'name' => topic['name'],
        'metadata' => METADATA_WEIGHTS.keys.index_with { |field| build_document(topic_field_text(topic, field)) },
        'faq_documents' => Array(topic['faq_ids']).filter_map { |faq_id| faq_documents[faq_id] }
      }
    end

    {
      'topics' => indexed_topics,
      'topic_idf' => inverse_document_frequency(indexed_topics.map { |topic| combined_metadata_document(topic['metadata']) }),
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

  def combined_metadata_document(metadata)
    tokens = metadata.values.flat_map { |document| document['tokens'].keys }.uniq
    { 'tokens' => tokens.index_with(true) }
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
