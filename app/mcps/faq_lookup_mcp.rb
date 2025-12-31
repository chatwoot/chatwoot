# frozen_string_literal: true

# Tool for searching the knowledge base and memories
# Used by the AI agent to find relevant information to answer customer questions
#
# Example usage in agent:
#   chat.with_tools([FaqLookupMcp])
#   response = chat.ask("Customer asks about refund policy")
#
class FaqLookupMcp < BaseMcp
  description 'Search the knowledge base and memories for information relevant to answering customer questions. ' \
              'Use this when you need to find specific information about products, policies, procedures, or ' \
              'when you want to recall previous interactions with this customer.'

  param :query, type: :string, desc: 'The search query - what information are you looking for?', required: true
  param :search_type, type: :string, desc: 'Type of search: "knowledge" for FAQs/docs, "memory" for past interactions, or "both" (default)',
                      required: false
  param :include_customer_context, type: :boolean, desc: 'Include customer-specific memories and preferences (default: true)',
                                   required: false

  def execute(query:, search_type: 'both', include_customer_context: true)
    validate_context!

    results = {
      knowledge: [],
      memories: [],
      query: query
    }

    begin
      # Search knowledge base (documents, FAQs)
      if %w[knowledge both].include?(search_type)
        results[:knowledge] = search_knowledge_base(query)
      end

      # Search memories (past interactions, learned information)
      if %w[memory both].include?(search_type)
        results[:memories] = search_memories(query, include_customer_context)
      end

      log_execution(
        { query: query, search_type: search_type },
        { knowledge_count: results[:knowledge].size, memory_count: results[:memories].size }
      )

      format_response(results)
    rescue StandardError => e
      log_execution(
        { query: query, search_type: search_type },
        {},
        success: false,
        error_message: e.message
      )
      error_response("Search failed: #{e.message}")
    end
  end

  private

  def search_knowledge_base(query)
    service = Aloo::VectorSearchService.new(
      assistant: current_assistant,
      account: current_account
    )
    service.search(query, limit: 5)
  end

  def search_memories(query, include_customer_context)
    service = Aloo::MemorySearchService.new(
      assistant: current_assistant,
      account: current_account
    )

    contact = include_customer_context ? current_contact : nil
    service.search(query, contact: contact, limit: 5)
  end

  def format_response(results)
    response_parts = []

    if results[:knowledge].any?
      response_parts << format_knowledge_results(results[:knowledge])
    end

    if results[:memories].any?
      response_parts << format_memory_results(results[:memories])
    end

    if response_parts.empty?
      return {
        success: true,
        message: 'No relevant information found in the knowledge base or memories.',
        results: []
      }
    end

    {
      success: true,
      message: response_parts.join("\n\n"),
      knowledge_results: results[:knowledge],
      memory_results: results[:memories]
    }
  end

  def format_knowledge_results(results)
    formatted = results.map.with_index do |result, index|
      "[#{index + 1}] #{result[:document_title]}\n#{result[:content]}"
    end

    "## Knowledge Base Results\n\n#{formatted.join("\n\n---\n\n")}"
  end

  def format_memory_results(results)
    formatted = results.map.with_index do |result, index|
      scope = result[:is_contact_scoped] ? '(Customer-specific)' : '(General)'
      "[#{index + 1}] #{result[:memory_type].humanize} #{scope}\n#{result[:content]}"
    end

    "## Relevant Memories\n\n#{formatted.join("\n\n")}"
  end
end
