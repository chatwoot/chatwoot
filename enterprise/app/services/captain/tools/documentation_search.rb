class Captain::Tools::DocumentationSearch < RubyLLM::Tool
  description 'Search through the documentation to find relevant answers'

  param :search_query,
        type: :string,
        desc: 'The search query to find relevant documentation'

  def initialize(assistant)
    super()
    @assistant = assistant
  end

  def execute(query)
    @assistant
      .responses
      .approved
      .search(query)
      .map { |response| format_response(response) }.join

    format_responses(responses)
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
