class Captain::Tools::SearchDocumentationService < Captain::Tools::BaseService
  def name
    'search_documentation'
  end

  def description
    'Search and retrieve documentation from knowledge base'
  end

  def parameters
    {
      type: 'object',
      properties: {
        search_query: {
          type: 'string',
          description: 'The search query to look up in the documentation.'
        }
      },
      required: ['search_query']
    }
  end

  def execute(arguments)
    query = arguments['search_query']
    Rails.logger.info { "#{self.class.name}: #{query}" }

    responses = assistant.responses.approved.search(query)

    return 'No FAQs found for the given query' if responses.empty?

    responses.map { |response| format_response(response) }.join
  end

  private

  def format_response(response)
    formatted_response = "
        Question: #{response.question}
        Answer: #{response.answer}
        "
    if response.documentable.present? && response.documentable.try(:external_link)
      formatted_response += "
          Source: #{response.documentable.external_link}
          "
    end

    formatted_response
  end
end
