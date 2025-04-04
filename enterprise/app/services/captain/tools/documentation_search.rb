class Captain::Tools::DocumentationSearch < RubyLLM::Tool
  description 'Search through the documentation to find relevant answers'

  param :search_query,
        type: :string,
        desc: 'The search query to find relevant documentation'

  def execute(search_query:)
    responses = ::Captain::AssistantResponse.approved.search(search_query)
    format_responses(responses)
  end

  private

  def format_responses(responses)
    responses.map do |response|
      formatted_response = {
        question: response.question,
        answer: response.answer
      }

      formatted_response[:source] = response.documentable.external_link if response.documentable.present? && response.documentable.try(:external_link)

      formatted_response
    end
  end
end
