# frozen_string_literal: true

# Tool for searching the knowledge base (documents, FAQs, webpages)
# Used by the AI agent to find relevant information to answer customer questions
#
# Example usage in agent:
#   chat.with_tools([KnowledgeLookupTool])
#   response = chat.ask("Customer asks about refund policy")
#
class KnowledgeLookupTool < BaseTool
  description 'Search the knowledge base for information about products, policies, procedures, FAQs, and documentation. ' \
              'Use this tool when you need to find specific information to answer a customer question accurately.'

  param :query, type: :string, desc: 'The search query - what information are you looking for?', required: true
  param :source_types, type: :array, desc: 'Optional filter by source types (e.g., ["file"], ["webpage"], or ["file", "webpage"])',
                       required: false

  def execute(query:, source_types: nil)
    validate_context!

    begin
      results = search_knowledge_base(query, source_types)

      log_execution(
        { query: query, source_types: source_types },
        { result_count: results.size }
      )

      format_response(results)
    rescue StandardError => e
      log_execution(
        { query: query, source_types: source_types },
        {},
        success: false,
        error_message: e.message
      )
      error_response("Knowledge search failed: #{e.message}")
    end
  end

  private

  def search_knowledge_base(query, source_types)
    service = Aloo::VectorSearchService.new(
      assistant: current_assistant,
      account: current_account
    )
    service.search(query, limit: 5, source_types: source_types)
  end

  def format_response(results)
    if results.empty?
      return {
        success: true,
        message: 'No relevant information found in the knowledge base.',
        results: []
      }
    end

    formatted = results.map.with_index do |result, index|
      "[#{index + 1}] #{result[:document_title]}\n#{result[:content]}"
    end

    {
      success: true,
      message: "## Knowledge Base Results\n\n#{formatted.join("\n\n---\n\n")}",
      results: results
    }
  end
end
