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
      format_responses(responses)
    end
  end

  private

  def record_retrieved_sources(tool_context, responses)
    return if responses.empty?

    metadata = tool_context.state[:cw_metadata] ||= {}
    metadata[:faq_ids] = Array(metadata[:faq_ids]) | responses.map(&:id)

    document_ids = responses.filter_map { |response| response.documentable_id if response.documentable_type == 'Captain::Document' }
    metadata[:document_ids] = Array(metadata[:document_ids]) | document_ids
  end

  def format_responses(responses)
    responses.map { |response| format_response(response) }.join
  end

  def format_response(response)
    formatted_response = "
        Question: #{response.question}
        Answer: #{response.answer}
        "
    if should_show_source?(response)
      formatted_response += "
          Source: #{response.documentable.external_link}
          "
    end

    formatted_response
  end

  def should_show_source?(response)
    return false if response.documentable.blank?
    return false unless response.documentable.try(:external_link)

    # Don't show source if it's a PDF placeholder
    external_link = response.documentable.external_link
    !external_link.start_with?('PDF:')
  end
end
