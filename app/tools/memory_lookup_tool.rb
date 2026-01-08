# frozen_string_literal: true

# Tool for searching memories (customer preferences, past interactions, learned information)
# Used by the AI agent to recall information about the customer or previous interactions
#
# Example usage in agent:
#   chat.with_tools([MemoryLookupTool])
#   response = chat.ask("What are this customer's preferences?")
#
class MemoryLookupTool < BaseTool
  description 'Search memories and past interactions to recall customer preferences, previous issues, or learned information. ' \
              'Use this when you want to personalize the response based on customer history or past conversations.'

  param :query, type: :string, desc: 'What are you trying to remember or find about this customer?', required: true
  param :include_customer_context, type: :boolean, desc: 'Include customer-specific memories and preferences (default: true)',
                                   required: false

  def execute(query:, include_customer_context: true)
    validate_context!

    begin
      results = search_memories(query, include_customer_context)

      log_execution(
        { query: query, include_customer_context: include_customer_context },
        { result_count: results.size }
      )

      format_response(results)
    rescue StandardError => e
      log_execution(
        { query: query, include_customer_context: include_customer_context },
        {},
        success: false,
        error_message: e.message
      )
      error_response("Memory search failed: #{e.message}")
    end
  end

  private

  def search_memories(query, include_customer_context)
    service = Aloo::MemorySearchService.new(
      assistant: current_assistant,
      account: current_account
    )

    contact = include_customer_context ? current_contact : nil
    service.search(query, contact: contact, limit: 5)
  end

  def format_response(results)
    if results.empty?
      return {
        success: true,
        message: 'No relevant memories found.',
        results: []
      }
    end

    formatted = results.map.with_index do |result, index|
      scope = result[:is_contact_scoped] ? '(Customer-specific)' : '(General)'
      "[#{index + 1}] #{result[:memory_type].humanize} #{scope}\n#{result[:content]}"
    end

    {
      success: true,
      message: "## Relevant Memories\n\n#{formatted.join("\n\n")}",
      results: results
    }
  end
end
