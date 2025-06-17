# frozen_string_literal: true

class Captain::Tools::MintlifySearchService < Captain::Tools::BaseService
  # A Copilot/Assistant tool that allows the LLM to run semantic searches over
  # Chatwoot's public Mintlify documentation. Results are fetched via the
  # ruby-mcp-client and streamed back as plain text.

  BASE_URL = 'https://developers.chatwoot.com'
  MAX_ITERATIONS = 3

  def name
    'mintlify_docs_search'
  end

  def description
    'Search Chatwoot documentation hosted on Mintlify and return the most relevant answer with comprehensive details.'
  end

  def parameters
    {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'The natural-language query to run against the documentation.'
        }
      },
      required: %w[query]
    }
  end

  # Executes the tool with iterative search capability.
  # @param arguments [Hash] – expects a single key `query`.
  # @return [String] – formatted block of Markdown text ready for the LLM.
  def execute(arguments)
    query = arguments['query']
    raise ArgumentError, 'query is required' if query.blank?

    Rails.logger.info("[MintlifySearchTool] Starting search for: #{query}")

    perform_search_with_error_handling(query)
  end

  def active?
    # Only activate if MCP client service is available and Mintlify is enabled
    mcp_client_service.client_for('mintlify').present?
  rescue StandardError => e
    Rails.logger.debug { "[MintlifySearchTool] Service inactive: #{e.message}" }
    false
  end

  # Health check method for monitoring
  def health_check
    {
      status: active? ? 'healthy' : 'unhealthy',
      last_check: Time.current,
      client_available: mcp_client_service.client_for('mintlify').present?
    }
  rescue StandardError => e
    {
      status: 'error',
      error: e.message,
      last_check: Time.current
    }
  end

  private

  def perform_search_with_error_handling(query)
    start_time = Time.current
    all_results = perform_iterative_search(query)

    return handle_search_results(all_results, start_time) if all_results.any?

    Rails.logger.warn("[MintlifySearchTool] No content found for query: #{query}")
    no_results_message
  rescue McpClientService::TimeoutError => e
    handle_timeout_error(e)
  rescue McpClientService::ConnectionError => e
    handle_connection_error(e)
  rescue McpClientService::ConfigurationError => e
    handle_configuration_error(e)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  def handle_search_results(results, start_time)
    combined_content = combine_search_results(results)
    result = format_response(combined_content, results.length)
    log_search_completion(start_time, results.length)
    result
  end

  def handle_timeout_error(error)
    Rails.logger.warn("[MintlifySearchTool] Search timeout: #{error.message}")
    'The documentation search timed out. Please try again with a more specific query.'
  end

  def handle_connection_error(error)
    Rails.logger.error("[MintlifySearchTool] Connection error: #{error.message}")
    'The documentation service is temporarily unavailable. Please try again in a few minutes.'
  end

  def handle_configuration_error(error)
    Rails.logger.error("[MintlifySearchTool] Configuration error: #{error.message}")
    'The documentation search service is not properly configured. Please contact support.'
  end

  def handle_unexpected_error(error)
    log_unexpected_error(error)
    'I encountered an error while searching the documentation. Please try again or contact support if the issue persists.'
  end

  def log_search_completion(start_time, iterations_count)
    duration = (Time.current - start_time).round(2)
    Rails.logger.debug { "[MintlifySearchTool] Iterative search completed in #{duration}s with #{iterations_count} iterations" }
  end

  def log_unexpected_error(error)
    Rails.logger.error("[MintlifySearchTool] Unexpected error: #{error.class}: #{error.message}")
    Rails.logger.error("[MintlifySearchTool] Backtrace: #{error.backtrace.join("\n")}")
  end

  def perform_iterative_search(original_query)
    results = []
    queries = generate_search_queries(original_query)

    queries.first(MAX_ITERATIONS).each_with_index do |query, index|
      result = execute_single_search(query, index)
      results << result if result

      # Short delay between iterations to be respectful
      sleep(0.5) if index < queries.length - 1
    end

    results
  end

  def execute_single_search(query, index)
    Rails.logger.debug { "[MintlifySearchTool] Iteration #{index + 1}: #{query}" }

    response = mcp_client_service.call_tool('mintlify', 'search', { query: query })

    return nil unless response && content?(response)

    content_text = extract_content_text(response['content'])
    return nil if content_text.blank?

    {
      query: query,
      content: content_text,
      iteration: index + 1
    }
  end

  def generate_search_queries(original_query)
    queries = [original_query]
    additional_queries = generate_additional_queries(original_query)
    queries.concat(additional_queries).uniq
  end

  def generate_additional_queries(original_query)
    case original_query.downcase
    when /install|setup|deploy/
      ["#{original_query} configuration", "#{original_query} requirements dependencies"]
    when /api|integration/
      ["#{original_query} authentication", "#{original_query} examples endpoints"]
    when /webhook|notification/
      ["#{original_query} configuration setup", "#{original_query} payload format"]
    when /troubleshoot|error|problem/
      ["#{original_query} common issues", "#{original_query} debugging guide"]
    else
      ["#{original_query} guide tutorial", "#{original_query} configuration examples"]
    end
  end

  def combine_search_results(results)
    return '' if results.empty?
    return results.first[:content] if results.length == 1

    results.map.with_index do |result, index|
      header = index.zero? ? "## Main Search Results\n\n" : "\n## Additional Information (Search #{index + 1})\n\n"
      "#{header}#{result[:content]}"
    end.join("\n\n")
  end

  def content?(response)
    response&.dig('content') && !response['content'].empty?
  end

  def extract_content_text(content)
    case content
    when Array
      content.map { |block| extract_text_from_block(block) }.join("\n")
    when Hash
      extract_text_from_block(content)
    when String
      content
    else
      content.to_s
    end
  end

  def extract_text_from_block(block)
    return block.to_s unless block.is_a?(Hash)

    text_content = block['text']
    return text_content.to_s if text_content

    block.to_s
  end

  def format_response(content_text, iteration_count)
    return no_results_message if content_text.blank?

    iteration_note = iteration_count > 1 ? " (#{iteration_count} searches combined)" : ''
    source_line = "*Source: [Chatwoot Developer Documentation](#{BASE_URL})*"

    "**Chatwoot Documentation Search Results#{iteration_note}:**\n\n#{content_text}\n\n" \
      "---\n*Base URL for relative links: #{BASE_URL}*\n#{source_line}"
  end

  def no_results_message
    "I couldn't find relevant information in the documentation for your query. Try rephrasing your question or asking about a different topic."
  end

  def mcp_client_service
    @mcp_client_service ||= McpClientService.instance
  end
end