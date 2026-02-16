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

    results = search_knowledge_base(query, source_types)
    format_response(results)
  rescue StandardError => e
    error_response("Knowledge search failed: #{e.message}")
  end

  private

  def search_knowledge_base(query, source_types)
    Aloo::Embedding.search(
      query,
      assistant: current_assistant,
      limit: 5,
      source_types: source_types
    )
  end

  def format_response(embeddings)
    if embeddings.empty?
      return {
        success: true,
        message: 'No relevant information found in the knowledge base.',
        results: []
      }
    end

    formatted = embeddings.map.with_index do |embedding, index|
      "[#{index + 1}] #{embedding.to_llm}"
    end

    {
      success: true,
      message: "## Knowledge Base Results\n\n#{formatted.join("\n\n---\n\n")}",
      results: embeddings.map { |e| { content: e.content, document_title: e.document&.title, similarity: e.similarity } }
    }
  end
end
