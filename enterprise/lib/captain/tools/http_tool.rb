require 'agents'

class Captain::Tools::HttpTool < Captain::Tools::BasePublicTool
  def initialize(assistant, custom_tool)
    @custom_tool = custom_tool
    super(assistant)
  end

  def active?
    @custom_tool.enabled?
  end

  def perform(tool_context, **params)
    return request(tool_context, params) unless gated?
    return perform_in_open_session(tool_context, params) if open_session?(tool_context.state)

    perform_for_customer(tool_context, params)
  rescue StandardError => e
    Rails.logger.error("HttpTool execution error for #{@custom_tool.slug}: #{e.class} - #{e.message}")
    failure_result('An error occurred while executing the request', tool_context.state)
  end

  # The same tool with its verified parameters shown to the model, for runs where an admin or an agent is the user
  def open_session_tool
    return self if @custom_tool.verified_sources.empty?

    @custom_tool.tool(@assistant, open_session: true)
  end

  def available_in_reply_suggestion?
    @custom_tool.http_method == 'GET'
  end

  # Runs where an admin or an agent is the user. Everywhere else a customer is, and has to be verified first.
  AGENT_FACING_SOURCES = %w[playground copilot_reply_suggestion].freeze
  EMAIL_IN_TEXT_PATTERN = /[^\s@<>"',;:()]+@[^\s@<>"',;:()]+/
  # In an open session the model supplied a verified value, so the result says nobody verified it
  UNVERIFIED_VALUE_NOTE = 'The email or identifier passed to this tool was not verified by the customer.'.freeze

  private

  def request(tool_context, params)
    url = @custom_tool.build_request_url(params)
    body = @custom_tool.build_request_body(params)
    @custom_tool.format_response(execute_http_request(url, body, tool_context))
  end

  def gated?
    @custom_tool.requires_email_verification? || @custom_tool.verified_sources.any?
  end

  def required_sources
    @custom_tool.verified_sources | (@custom_tool.requires_email_verification? ? ['verified.email'] : [])
  end

  # Every source the tool needs must be verified, and the verified email is the only email the request can carry
  def perform_for_customer(tool_context, params)
    state = tool_context.state
    verified_values = stored_verified_values(state)
    missing = required_sources - verified_values.keys
    return identity_verification_required_message(state) if missing.include?('verified.identifier')
    return email_verification_required_message(state) if missing.include?('verified.email')

    verified_email = verified_values['verified.email']
    return other_email_message(state, verified_email) if verified_email && other_email?(params, verified_email)

    request(tool_context, @custom_tool.with_verified_values(params, verified_values))
  end

  # A value the customer verified is still used. The model supplies the rest, and the result says they were not verified.
  def perform_in_open_session(tool_context, params)
    verified_values = stored_verified_values(tool_context.state)
    supplied_sources = @custom_tool.verified_sources - verified_values.keys
    return supplied_value_required_message(tool_context.state) if blank_supplied_value?(params, supplied_sources)

    result = request(tool_context, @custom_tool.with_verified_values(params, verified_values))
    supplied_sources.any? ? "#{result}\n\n#{UNVERIFIED_VALUE_NOTE}" : result
  end

  def blank_supplied_value?(params, sources)
    @custom_tool.param_schema.any? { |param_def| sources.include?(param_def['source']) && params[param_def['name'].to_sym].to_s.strip.blank? }
  end

  def other_email?(params, verified_email)
    params.values.grep(String).flat_map { |value| value.scan(EMAIL_IN_TEXT_PATTERN) }.any? { |email| !email.casecmp?(verified_email) }
  end

  def open_session?(state)
    AGENT_FACING_SOURCES.include?(state&.dig(:source))
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

  def supplied_value_required_message(state)
    names = @custom_tool.param_schema.select { |param_def| param_def['source'] }.pluck('name').join(', ')
    failure_result("This tool needs the customer's #{names}. Pass it as a parameter.", state)
  end

  def other_email_message(state, verified_email)
    failure_result(
      "This tool can only run for #{verified_email}, the email this customer verified. " \
      'Call it again with that email only. To use another email, verify it with a one-time code first.',
      state
    )
  end

  def email_verification_required_message(state)
    failure_result(
      'This tool needs a verified email, and this customer has not verified an email yet. ' \
      'Verify their email with a one-time code first, then call this tool again. ' \
      'If that is not possible, ask whether they want to talk to a support agent.',
      state
    )
  end

  def identity_verification_required_message(state)
    failure_result(
      'This tool needs a customer whose identity is verified by the website or app they are signed in to, and this customer is not. ' \
      'This cannot be done in the conversation. Ask whether they want to talk to a support agent.',
      state
    )
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
