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
              'Use this tool when you need to find specific information to answer a customer question accurately. ' \
              'ALWAYS provide a translated_query to ensure cross-lingual search coverage.'

  param :query, type: :string, desc: 'The search query - what information are you looking for?', required: true
  param :translated_query,
        type: :string,
        desc: 'A translation of the query into a different language to enable cross-lingual search. ' \
              'ALWAYS provide this. If the query is in Arabic, translate to English. ' \
              'If the query is in English, translate to Arabic. ' \
              'For other languages, translate to English.',
        required: false

  def execute(query:, translated_query: nil)
    validate_context!

    results = search_with_fallback(query, translated_query)
    format_response(results)
  rescue StandardError => e
    error_response("Knowledge search failed: #{e.message}")
  end

  private

  def search_with_fallback(query, translated_query)
    primary = search_knowledge_base(query)
    return primary if translated_query.blank? || translated_query.strip.downcase == query.strip.downcase

    translated_results = search_knowledge_base(translated_query)
    merge_results(primary, translated_results)
  end

  def merge_results(primary, secondary)
    (primary + secondary)
      .group_by(&:id)
      .values
      .map { |dupes| dupes.max_by { |e| e.similarity || 0 } }
      .sort_by { |e| -(e.similarity || 0) }
      .first(5)
  end

  def search_knowledge_base(query)
    Aloo::Embedding.search(
      query,
      assistant: current_assistant,
      limit: 5
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
