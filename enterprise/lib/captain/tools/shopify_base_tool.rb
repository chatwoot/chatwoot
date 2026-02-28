class Captain::Tools::ShopifyBaseTool < Captain::Tools::BasePublicTool
  SHOPIFY_APP_ID = 'shopify'.freeze
  V2_FEATURE_FLAG = 'captain_integration_v2'.freeze
  EMAIL_REGEX = /\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b/i
  PHONE_REGEX = /(?:\+\d[\d\s().-]{7,}\d|\(?\d{3}\)?[-.\s]\d{3}[-.\s]\d{4})/

  def active?
    v2_enabled? && shopify_connected?
  end

  private

  def v2_enabled?
    @assistant.account.feature_enabled?(V2_FEATURE_FLAG)
  end

  def shopify_connected?
    Integrations::Hook.exists?(account_id: @assistant.account_id, app_id: SHOPIFY_APP_ID, status: :enabled)
  end

  def eligibility_error_message
    unless v2_enabled?
      log_tool_usage('shopify_tool_not_eligible', { reason: 'captain_v2_disabled' })
      return 'This Shopify tool is available only for Captain V2.'
    end

    unless shopify_connected?
      log_tool_usage('shopify_tool_not_eligible', { reason: 'shopify_not_connected' })
      return 'Shopify integration is not connected for this account.'
    end

    nil
  end

  def resolve_contact_identity(state, override_identity = {})
    inferred_identity = extract_identity_from_current_input(state)
    history_identity = extract_identity_from_trace_history(state)

    {
      email: resolve_identity_value(:email, override_identity, state, inferred_identity, history_identity),
      phone_number: resolve_identity_value(:phone_number, override_identity, state, inferred_identity, history_identity)
    }
  end

  def format_domain_error(error)
    case error&.dig(:code)
    when :not_connected
      'Shopify integration is not connected. Please connect Shopify and try again.'
    when :insufficient_scope
      'Shopify integration requires additional permissions. Please reauthorize Shopify integration and try again.'
    when :missing_identifier
      'I need the contact email or phone number to look up Shopify orders.'
    when :no_results
      error[:message].presence || 'No matching Shopify records were found.'
    else
      'I could not fetch Shopify data right now. Please try again shortly.'
    end
  end

  def extract_identity_from_current_input(state)
    current_input = extract_current_input_text(state)
    return empty_identity if current_input.blank?

    extract_identity_from_text(current_input)
  end

  def extract_current_input_text(state)
    raw_input = state&.dig(:captain_v2_trace_current_input).to_s
    return '' if raw_input.blank?

    extract_trace_content_text(parse_trace_payload(raw_input))
  end

  def extract_identity_from_trace_history(state)
    trace_input = state&.dig(:captain_v2_trace_input).to_s
    parsed_input = parse_trace_payload(trace_input)
    return empty_identity unless parsed_input.is_a?(Array)

    user_messages = parsed_input.reverse.filter_map { |entry| trace_user_text(entry) }
    first_identity_from_messages(user_messages)
  end

  def extract_trace_content_text(content)
    return '' if content.blank?
    return content.to_s unless content.is_a?(Array)

    content.filter_map { |part| part['text'] if part.is_a?(Hash) && part['type'] == 'text' }.join(' ')
  end

  def trace_user_text(entry)
    return unless entry.is_a?(Hash) && entry['role'] == 'user'

    extract_trace_content_text(entry['content']).presence
  end

  def first_identity_from_messages(messages)
    identity = empty_identity

    messages.each do |message|
      identity[:email] ||= normalize_email(message)
      identity[:phone_number] ||= normalize_phone(message[PHONE_REGEX])
      break if identity.values.all?(&:present?)
    end

    identity
  end

  def extract_identity_from_text(text)
    {
      email: normalize_email(text),
      phone_number: normalize_phone(text[PHONE_REGEX])
    }
  end

  def resolve_identity_value(key, override_identity, state, inferred_identity, history_identity)
    [
      normalized_identity_value(key, override_identity[key]),
      normalized_identity_value(key, state&.dig(:contact, key)),
      normalized_identity_value(key, inferred_identity[key]),
      normalized_identity_value(key, history_identity[key])
    ].find(&:present?)
  end

  def normalized_identity_value(key, value)
    return normalize_email(value) if key == :email

    normalize_phone(value)
  end

  def empty_identity
    { email: nil, phone_number: nil }
  end

  def parse_trace_payload(raw_input)
    return raw_input unless raw_input.strip.start_with?('[', '{')

    JSON.parse(raw_input)
  rescue JSON::ParserError
    raw_input
  end

  def normalize_email(raw_value)
    value = raw_value.to_s.strip
    return nil if value.blank?

    value[EMAIL_REGEX]
  end

  def normalize_phone(raw_value)
    value = raw_value.to_s.strip
    return nil if value.blank?

    normalized = value.gsub(/[^\d+]/, '')
    return nil unless normalized.match?(/\A\+?\d{7,15}\z/)

    normalized
  end
end
