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
  def stored_verified_email(state)
    conversation = find_conversation(state)
    conversation && Captain::EmailVerification.new(conversation).verified_email
  end

  def safe_to_run_after_new_customer_message?
    @custom_tool.http_method == 'GET'
  end

  # Limit response size to prevent memory exhaustion and match LLM token limits
  # 1MB of text ≈ 250K tokens, which exceeds most LLM context windows
  MAX_RESPONSE_SIZE = 1.megabyte
  # Customer details Chatwoot sends with every request. They are dropped on a redirect to another origin, like credentials.
  PERSONAL_HEADERS = %w[X-Chatwoot-Contact-Email X-Chatwoot-Contact-Phone X-Chatwoot-Verified-Email].freeze

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
      sensitive_headers: auth_headers.keys + @custom_tool.headers.keys + PERSONAL_HEADERS,
      http_basic_authentication: @custom_tool.build_basic_auth_credentials,
      max_bytes: MAX_RESPONSE_SIZE,
      validate_content_type: false
    ) { |result| response_body = result.tempfile.read }
    response_body
  end

  def request_headers(tool_context, json_body, auth_headers)
    headers = @custom_tool.headers.merge(auth_headers)
    headers.merge!(@custom_tool.build_metadata_headers(tool_context&.state || {}))
    # The contact email can be typed by anyone, so the email the customer verified travels in its own header.
    # The admin test request runs without a conversation, so it has no customer to look up.
    verified_email = stored_verified_email(tool_context.state) if tool_context
    headers['X-Chatwoot-Verified-Email'] = verified_email if verified_email
    headers['Content-Type'] = 'application/json' if json_body.present?
    headers
  end
end
