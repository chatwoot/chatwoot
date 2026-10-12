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
    return perform_with_verified_session(tool_context, params) if @custom_tool.requires_email_verification?

    request(tool_context, params)
  rescue StandardError => e
    Rails.logger.error("HttpTool execution error for #{@custom_tool.slug}: #{e.class} - #{e.message}")
    failure_result('An error occurred while executing the request', tool_context.state)
  end

  # The same tool with an email parameter for the model, for runs where an admin or an agent is the user
  def open_session_tool
    return self unless @custom_tool.uses_session_email?

    @custom_tool.tool(@assistant, open_session: true)
  end

  def available_in_reply_suggestion?
    @custom_tool.http_method == 'GET'
  end

  # Runs where an admin or an agent is the user. Everywhere else a customer is, and has to verify first.
  AGENT_FACING_SOURCES = %w[playground copilot_reply_suggestion].freeze
  OPEN_SESSION_EMAIL_PARAM = Concerns::Toolable::OPEN_SESSION_EMAIL_PARAM
  # In an open session the model supplied the email, so the result says nobody verified it
  EMAIL_IN_TEXT_PATTERN = /[^\s@<>"',;:()]+@[^\s@<>"',;:()]+/
  UNVERIFIED_EMAIL_NOTE = 'This email was not verified by the customer.'.freeze

  private

  def request(tool_context, params, session = {})
    url = @custom_tool.build_request_url(params, session)
    body = @custom_tool.build_request_body(params, session)
    @custom_tool.format_response(execute_http_request(url, body, tool_context))
  end

  # A customer has to verify an email first. In an open session the model supplies the email in their place.
  def perform_with_verified_session(tool_context, params)
    state = tool_context.state
    verified_email = stored_verified_email(state)
    return perform_for_customer(tool_context, params, verified_email) unless open_session?(state)
    return request(tool_context, params, { verified_email: verified_email }) if verified_email.present? || !@custom_tool.uses_session_email?

    supplied_email = params[OPEN_SESSION_EMAIL_PARAM].to_s.strip
    return session_email_required_message(state) if supplied_email.blank?

    "#{request(tool_context, params, { verified_email: supplied_email })}\n\n#{UNVERIFIED_EMAIL_NOTE}"
  end

  # The verified email is the only email a customer's request can carry, in the session or in a parameter the model fills in
  def perform_for_customer(tool_context, params, verified_email)
    return email_verification_required_message(tool_context.state) if verified_email.blank?
    return other_email_message(tool_context.state, verified_email) if other_email?(params, verified_email)

    request(tool_context, params, { verified_email: verified_email })
  end

  def other_email?(params, verified_email)
    params.values.grep(String).flat_map { |value| value.scan(EMAIL_IN_TEXT_PATTERN) }.any? { |email| !email.casecmp?(verified_email) }
  end

  def open_session?(state)
    AGENT_FACING_SOURCES.include?(state&.dig(:source))
  end

  # Read from the stored verification on every call, never from the run state the model can influence
  def stored_verified_email(state)
    contact_inbox = find_contact_inbox(state)
    contact_inbox && Captain::EmailVerification.new(contact_inbox).verified_email
  end

  def session_email_required_message(state)
    failure_result("This tool needs the customer's email. Pass it as the email parameter.", state)
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
