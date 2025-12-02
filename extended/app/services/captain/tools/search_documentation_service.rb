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

  def execute(args)
    query = args['search_query']
    Rails.logger.info("Searching documentation for: #{query}")

    results = @assistant.responses.approved.search(query)

    return 'No FAQs found for the given query' if results.empty?

    format_results(results)
  end

  private

  def perform_search(query)
    # Assuming assistant has a responses association that supports search
    @assistant.responses.approved.search(query)
  end

  def format_results(results)
    results.map do |item|
      format_item(item)
    end.join("\n\n")
  end

  def format_item(item)
    text = "Q: #{item.question}\nA: #{item.answer}"

    if item.documentable.present? && item.documentable.respond_to?(:external_link) && item.documentable.external_link.present?
      text += "\nSource: #{item.documentable.external_link}"
    end

    text
  end
end
