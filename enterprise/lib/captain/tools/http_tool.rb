require 'agents'

class Captain::Tools::HttpTool < Agents::Tool
  def initialize(assistant, custom_tool)
    @assistant = assistant
    @custom_tool = custom_tool
    super()
  end

  def active?
    @custom_tool.enabled?
  end

  def perform(tool_context, **params)
    url = @custom_tool.build_request_url(params)
    body = @custom_tool.build_request_body(params)

    response_body = execute_http_request(url, body, tool_context)
    @custom_tool.format_response(response_body)
  rescue StandardError => e
    Rails.logger.error("HttpTool execution error for #{@custom_tool.slug}: #{e.class} - #{e.message}")
    'An error occurred while executing the request'
  end

  private

  # Limit response size to prevent memory exhaustion and match LLM token limits
  # 1MB of text ≈ 250K tokens, which exceeds most LLM context windows
  MAX_RESPONSE_SIZE = 1.megabyte

  # Route through SafeFetch so custom tool requests share the app's centralized HTTP
  # fetching (resolution, timeouts, response size limits, and redirect handling).
  def execute_http_request(url, body, tool_context)
    json_body = body if @custom_tool.http_method == 'POST'

    response_body = +''
    SafeFetch.fetch(
      url,
      method: @custom_tool.http_method == 'POST' ? :post : :get,
      body: json_body,
      headers: request_headers(tool_context, json_body),
      http_basic_authentication: @custom_tool.build_basic_auth_credentials,
      max_bytes: MAX_RESPONSE_SIZE,
      validate_content_type: false
    ) { |result| response_body = result.tempfile.read }
    response_body
  end

  def request_headers(tool_context, json_body)
    headers = @custom_tool.build_auth_headers
    headers.merge!(@custom_tool.build_metadata_headers(tool_context&.state || {}))
    headers['Content-Type'] = 'application/json' if json_body.present?
    headers
  end
end
