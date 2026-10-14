require 'agents'

class Captain::Tools::HttpTool < Captain::Tools::BasePublicTool
  def initialize(assistant, custom_tool)
    @custom_tool = custom_tool
    super(assistant)
  end

  attr_reader :custom_tool

  # Whether the model sees and fills a verified parameter. Each subclass answers for the user it serves.
  def self.model_fills_verified_values?
    false
  end

  def active?
    @custom_tool.enabled?
  end

  def perform(tool_context, **params)
    request(tool_context, params)
  rescue StandardError => e
    Rails.logger.error("HttpTool execution error for #{@custom_tool.slug}: #{e.class} - #{e.message}")
    failure_result('An error occurred while executing the request', tool_context.state)
  end

  def available_in_reply_suggestion?
    @custom_tool.http_method == 'GET'
  end

  private

  def request(tool_context, params)
    url = @custom_tool.build_request_url(params)
    body = @custom_tool.build_request_body(params)
    @custom_tool.format_response(execute_http_request(url, body, tool_context))
  end

  # Read from stored data on every call, never from the run state the model can influence
  def stored_verified_values(state)
    contact_inbox = find_contact_inbox(state)
    return {} unless contact_inbox

    {
      'verified.email' => Captain::EmailVerification.new(contact_inbox).verified_email,
      'verified.identifier' => (contact_inbox.contact.identifier if contact_inbox.hmac_verified?)
    }.compact_blank
  end

  def safe_to_run_after_new_customer_message?
    @custom_tool.http_method == 'GET'
  end

  # Limit response size to prevent memory exhaustion and match LLM token limits
  # 1MB of text ≈ 250K tokens, which exceeds most LLM context windows
  MAX_RESPONSE_SIZE = 1.megabyte

  # Route through SafeFetch so custom tool requests share the app's centralized HTTP
  # fetching (resolution, timeouts, response size limits, and redirect handling).
  def execute_http_request(url, body, tool_context)
    # Templates can change the URL when rendered, so the final URL is checked before any credentials are sent
    raise ArgumentError, 'Custom tool requests must use HTTPS' unless URI.parse(url).scheme == 'https'

    json_body = body unless @custom_tool.http_method == 'GET'
    auth_headers = @custom_tool.build_auth_headers

    response_body = +''
    SafeFetch.fetch(
      url,
      method: @custom_tool.http_method.downcase.to_sym,
      body: json_body,
      headers: request_headers(tool_context, json_body, auth_headers),
      sensitive_headers: auth_headers.keys + @custom_tool.headers.keys,
      http_basic_authentication: @custom_tool.build_basic_auth_credentials,
      max_bytes: MAX_RESPONSE_SIZE,
      validate_content_type: false
    ) { |result| response_body = result.tempfile.read }
    response_body
  end

  def request_headers(tool_context, json_body, auth_headers)
    headers = @custom_tool.headers.merge(auth_headers)
    headers.merge!(@custom_tool.build_metadata_headers(tool_context&.state || {}))
    headers['Content-Type'] = 'application/json' if json_body.present?
    headers
  end
end
