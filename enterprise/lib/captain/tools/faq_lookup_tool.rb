class Captain::Tools::FaqLookupTool < Captain::Tools::BasePublicTool
  description 'Search FAQ responses using semantic similarity to find relevant answers'
  param :query, type: 'string', desc: 'The question or topic to search for in the FAQ database'

  def perform(tool_context, query:)
    log_tool_usage('searching', { query: query })

    # Use existing vector search on approved responses
    responses = @assistant.responses.approved.search(query).to_a
    record_retrieved_sources(tool_context, responses)

    if responses.empty?
      log_tool_usage('no_results', { query: query })
      "No relevant FAQs found for: #{query}"
    else
      log_tool_usage('found_results', { query: query, count: responses.size })
      format_responses(tool_context, responses)
    end
  end

  private

  def record_retrieved_sources(tool_context, responses)
    return if responses.empty?

    metadata = tool_context.state[:cw_metadata] ||= {}
    metadata[:faq_ids] = Array(metadata[:faq_ids]) | responses.map(&:id)

    document_ids = document_responses(responses).map(&:documentable_id)
    metadata[:document_ids] = Array(metadata[:document_ids]) | document_ids
    metadata[:message_sources] = Array(metadata[:message_sources]) | message_sources(document_responses(responses))

    document_ids.each { |document_id| citation_source_number(tool_context, document_id) }
  end

  def document_responses(responses)
    responses.select { |response| response.documentable_type == 'Captain::Document' }
  end

  def message_sources(responses)
    responses.map { |response| { assistant_response_id: response.id, document_id: response.documentable_id } }
  end

  def format_responses(tool_context, responses)
    responses.map { |response| format_response(tool_context, response) }.join
  end

  def format_response(tool_context, response)
    formatted_response = "
        Question: #{response.question}
        Answer: #{response.answer}
        "
    if response.documentable_type == 'Captain::Document'
      formatted_response += "
          Source marker: [[source:#{citation_source_number(tool_context, response.documentable_id)}]]
          "
    end

    formatted_response
  end

  def citation_source_number(tool_context, document_id)
    source_map = tool_context.state[:captain_v2_citation_source_map] ||= {}
    existing_number = source_map.find { |_number, id| id.to_i == document_id }&.first
    return existing_number if existing_number.present?

    source_number = (source_map.keys.map(&:to_i).max || 0) + 1
    source_map[source_number.to_s] = document_id
    source_number.to_s
  end
end
