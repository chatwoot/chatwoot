class Captain::Tools::FaqLookupTool < Captain::Tools::BasePublicTool
  name 'faq_lookup'
  description 'Search FAQ responses using semantic similarity to find relevant answers'
  param :query, type: 'string', desc: 'The question or topic to search for in the FAQ database'

  def perform(_tool_context, query:)
    log_tool_usage('searching', { query: query })

    # Use existing vector search on approved responses
    responses = @assistant.responses.approved.search(query)

    if responses.empty?
      log_tool_usage('no_results', { query: query })
      "No relevant FAQs found for: #{query}"
    else
      log_tool_usage('found_results', { query: query, count: responses.count })
      format_responses(responses)
    end
  end

  private

  def format_responses(responses)
    formatted = responses.map.with_index(1) do |response, index|
      result = "\n#{index}. **Q:** #{response.question}\n   **A:** #{response.answer}"

      # Include source if available
      result += "\n   **Source:** #{response.documentable.external_link}" if response.documentable&.external_link

      result
    end

    "Found #{responses.count} relevant FAQ(s):#{formatted.join("\n")}"
  end
end
