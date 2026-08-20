class Captain::Tools::FaqLookupTool < Captain::Tools::BasePublicTool
  description 'Search FAQ responses using semantic similarity to find relevant answers'
  param :query, type: 'string', desc: 'The question or topic to search for in the FAQ database'

  def perform(tool_context, query:)
    log_tool_usage('searching', { query: query })

    # Use existing vector search on approved responses
    responses = @assistant.responses.approved.search(query).includes(:documentable).to_a
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

  def safe_to_run_after_new_customer_message?
    true
  end

  def record_retrieved_sources(tool_context, responses)
    return if responses.empty?

    metadata = tool_context.state[:cw_metadata] ||= {}
    metadata[:faq_ids] = Array(metadata[:faq_ids]) | responses.map(&:id)

    responses_by_type = responses.group_by(&:documentable_type)
    document_ids = Array(responses_by_type['Captain::Document']).map(&:documentable_id)
    metadata[:document_ids] = Array(metadata[:document_ids]) | document_ids

    used_faq_ids = Array(responses_by_type['User']).map(&:id)
    metadata[:used_faq_ids] = Array(metadata[:used_faq_ids]) | used_faq_ids
  end

  def format_responses(tool_context, responses)
    responses.map { |response| format_response(tool_context, response) }.join
  end

  def format_response(tool_context, response)
    formatted_response = "
        FAQ result:
        "
    if @assistant.citations_enabled? && response.customer_visible_source_url.present?
      formatted_response += "
          Citation index: #{citation_index(tool_context, response)}
          "
    end
    formatted_response += "
        Question: #{response.question}
        Answer: #{response.answer}
        "

    formatted_response
  end

  def citation_index(tool_context, response)
    citation_document_ids = tool_context.state[Captain::Assistant::CITATION_SOURCES_STATE_KEY] ||= {}
    existing_index = citation_document_ids.find { |_index, document_id| document_id == response.documentable_id }&.first
    return existing_index if existing_index.present?

    next_citation_index = citation_document_ids.size + 1
    citation_document_ids[next_citation_index] = response.documentable_id
    next_citation_index
  end
end
