class Captain::Llm::KnowledgeMapBaseService < Captain::BaseTaskService
  MAX_INPUT_CHARACTERS = 100_000

  private

  def generate(schema:, system_prompt:, payload:)
    response = make_api_call(
      feature: 'knowledge_map_generation',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: JSON.generate(payload) }
      ],
      schema: schema
    )
    raise Captain::Llm::KnowledgeMapGenerationError, response[:error] if response[:error]
    raise Captain::Llm::KnowledgeMapGenerationError, 'Knowledge map generation returned an invalid response' unless response[:message].is_a?(Hash)

    record_usage(response[:usage])
    response[:message].deep_stringify_keys
  end

  def normalize_relationships(raw_relationships, allowed_ids:)
    relationships = Array(raw_relationships).filter_map do |raw_relationship|
      relationship = raw_relationship.to_h.deep_symbolize_keys
      subject = clean_string(relationship[:subject], 100)
      predicate = clean_string(relationship[:predicate], 80)
      object = clean_string(relationship[:object], 100)
      faq_ids = normalize_known_ids(relationship[:faq_ids], allowed_ids)
      next if subject.blank? || predicate.blank? || object.blank? || faq_ids.empty?

      { subject: subject, predicate: predicate, object: object, faq_ids: faq_ids }
    end
    merge_duplicate_cited_items(relationships, [:subject, :predicate, :object]).first(6)
  end

  def normalize_distinctions(raw_distinctions, allowed_ids:)
    distinctions = Array(raw_distinctions).filter_map do |raw_distinction|
      distinction = raw_distinction.to_h.deep_symbolize_keys
      statement = clean_string(distinction[:statement], 300)
      faq_ids = normalize_known_ids(distinction[:faq_ids], allowed_ids)
      next if statement.blank? || faq_ids.empty?

      { statement: statement, faq_ids: faq_ids }
    end
    merge_duplicate_cited_items(distinctions, [:statement]).first(6)
  end

  def merge_duplicate_cited_items(items, fields)
    items.group_by { |item| fields.map { |field| item[field].downcase } }.values.map do |duplicates|
      duplicates.first.merge(faq_ids: normalize_ids(duplicates.flat_map { |item| item[:faq_ids] }))
    end
  end

  def normalize_ids(values)
    Array(values).filter_map { |value| Integer(value, exception: false) }.uniq.sort
  end

  def normalize_known_ids(values, allowed_ids)
    normalize_ids(values) & allowed_ids
  end

  def clean_string(value, maximum_length)
    value.to_s.gsub(/\s+/, ' ').strip.first(maximum_length)
  end

  def clean_strings(values, limit:, length:)
    unique_strings(Array(values).filter_map { |value| clean_string(value, length).presence }).first(limit)
  end

  def unique_strings(values)
    values.uniq(&:downcase)
  end

  def collect_faq_ids(value)
    case value
    when Hash
      value.flat_map { |key, child| key.to_s.end_with?('faq_ids') ? normalize_ids(child) : collect_faq_ids(child) }.uniq.sort
    when Array
      value.flat_map { |child| collect_faq_ids(child) }.uniq.sort
    else
      []
    end
  end

  def chunked(items, max_items: nil)
    chunks = []
    current_chunk = []
    current_length = 0

    items.each do |item|
      item_length = JSON.generate(item).length
      full_chunk = max_items && current_chunk.length >= max_items
      if current_chunk.any? && (full_chunk || current_length + item_length > MAX_INPUT_CHARACTERS)
        chunks << current_chunk
        current_chunk = []
        current_length = 0
      end

      current_chunk << item
      current_length += item_length
    end

    chunks << current_chunk if current_chunk.any?
    chunks
  end

  def record_usage(response_usage)
    usage.each_key { |key| usage[key] += response_usage&.dig(key).to_i }
  end

  def usage
    @usage ||= %w[prompt_tokens completion_tokens total_tokens].index_with { 0 }
  end

  def captain_tasks_enabled?
    true
  end

  def counts_toward_usage?
    false
  end

  def build_follow_up_context?
    false
  end
end
