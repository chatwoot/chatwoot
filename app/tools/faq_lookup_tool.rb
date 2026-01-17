# frozen_string_literal: true

# DEPRECATED: Use KnowledgeLookupTool and MemoryLookupTool instead
# This tool is kept for backward compatibility with existing agent conversations
#
# Example usage in agent:
#   chat.with_tools([FaqLookupTool])
#   response = chat.ask("Customer asks about refund policy")
#
class FaqLookupTool < BaseTool
  description '[DEPRECATED] Search the knowledge base and memories. ' \
              'Use knowledge_lookup for knowledge base and memory_lookup for memories instead.'

  param :query, type: :string, desc: 'The search query - what information are you looking for?', required: true
  param :search_type, type: :string, desc: 'Type of search: "knowledge" for FAQs/docs, "memory" for past interactions, or "both" (default)',
                      required: false
  param :include_customer_context, type: :boolean, desc: 'Include customer-specific memories and preferences (default: true)',
                                   required: false

  def execute(query:, search_type: 'both', include_customer_context: true)
    validate_context!

    Rails.logger.warn('[DEPRECATED] FaqLookupTool is deprecated. Use KnowledgeLookupTool and MemoryLookupTool instead.')

    results = {
      knowledge: [],
      memories: [],
      query: query
    }

    begin
      if %w[knowledge both].include?(search_type)
        knowledge_tool = KnowledgeLookupTool.new
        knowledge_result = knowledge_tool.execute(query: query)
        results[:knowledge] = knowledge_result[:results] || []
      end

      if %w[memory both].include?(search_type)
        memory_tool = MemoryLookupTool.new
        memory_result = memory_tool.execute(query: query, include_customer_context: include_customer_context)
        results[:memories] = memory_result[:results] || []
      end

      format_response(results)
    rescue StandardError => e
      error_response("Search failed: #{e.message}")
    end
  end

  private

  def format_response(results)
    response_parts = []

    response_parts << format_knowledge_results(results[:knowledge]) if results[:knowledge].any?

    response_parts << format_memory_results(results[:memories]) if results[:memories].any?

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
