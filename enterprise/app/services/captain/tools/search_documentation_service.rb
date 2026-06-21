class Captain::Tools::SearchDocumentationService < Captain::Tools::BaseTool
  def self.name
    'search_documentation'
  end
  description 'Search and retrieve documentation from knowledge base'

  param :query, desc: 'Search Query', required: true

  # Structured references for the FAQs/documents surfaced across all searches in a run.
  # Consumed by the chat service to persist citations on the generated message.
  def citations
    @citations ||= []
  end

  def execute(query:)
    Rails.logger.info { "#{self.class.name}: #{query}" }

    translated_query = Captain::Llm::TranslateQueryService
                       .new(account: assistant.account)
                       .translate(query, target_language: assistant.account.locale_english_name)

    responses = assistant.responses.approved.search(translated_query)

    return 'No FAQs found for the given query' if responses.empty?

    capture_citations(responses)
    responses.map { |response| format_response(response) }.join
  end

  private

  def capture_citations(responses)
    responses.each do |response|
      citations << {
        'response_id' => response.id,
        'title' => response.question,
        'source' => response.documentable.try(:external_link),
        'document_id' => response.documentable_id
      }
    end
  end

  def format_response(response)
    formatted_response = "
        Source ID: #{response.id}
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
