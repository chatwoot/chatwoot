module Concerns::Toolable
  extend ActiveSupport::Concern

  # Isolated namespace for user-defined custom tool classes.
  # Keeps them separate from built-in classes in Captain::Tools (e.g., HttpTool, CustomHttpTool).
  module CustomTools; end

  def tool(assistant, base_class: Captain::Tools::HttpTool, pipeline: nil, **)
    base_class = pipeline == :ruby_llm ? Captain::Tools::CatalogRubyLlmTool : Captain::Tools::CatalogTool if source_catalog?
    tool_class = Captain::ToolCatalog::ToolClassBuilder.new(
      custom_tool: self,
      base_class: base_class,
      namespace: CustomTools
    ).build
    tool_class.new(assistant, self, **)
  end

  def build_request_url(params)
    return endpoint_url if endpoint_url.blank? || endpoint_url.exclude?('{{')

    render_template(endpoint_url, params)
  end

  def build_request_body(params)
    return nil if request_template.blank?

    render_template(request_template, params)
  end

  def build_auth_headers
    return {} if auth_none?

    case auth_type
    when 'bearer'
      { 'Authorization' => "Bearer #{auth_config['token']}" }
    when 'api_key'
      { auth_config['name'] => auth_config['key'] }
    else
      {}
    end
  end

  def build_basic_auth_credentials
    return nil unless auth_type == 'basic'

    [auth_config['username'], auth_config['password']]
  end

  def build_metadata_headers(state)
    {}.tap do |headers|
      add_base_headers(headers, state)
      add_conversation_headers(headers, state[:conversation]) if state[:conversation]
      add_contact_headers(headers, state[:contact]) if state[:contact]
      add_contact_inbox_headers(headers, state[:contact_inbox])
    end
  end

  def add_base_headers(headers, state)
    headers['X-Chatwoot-Account-Id'] = state[:account_id].to_s if state[:account_id]
    headers['X-Chatwoot-Assistant-Id'] = state[:assistant_id].to_s if state[:assistant_id]
    headers['X-Chatwoot-Tool-Slug'] = slug if slug.present?
  end

  def add_conversation_headers(headers, conversation)
    headers['X-Chatwoot-Conversation-Id'] = conversation[:id].to_s if conversation[:id]
    headers['X-Chatwoot-Conversation-Display-Id'] = conversation[:display_id].to_s if conversation[:display_id]
  end

  def add_contact_headers(headers, contact)
    headers['X-Chatwoot-Contact-Id'] = contact[:id].to_s if contact[:id]
    headers['X-Chatwoot-Contact-Email'] = contact[:email].to_s if contact[:email].present?
    headers['X-Chatwoot-Contact-Phone'] = contact[:phone_number].to_s if contact[:phone_number].present?
  end

  def add_contact_inbox_headers(headers, contact_inbox)
    headers['X-Chatwoot-Contact-Inbox-Id'] = contact_inbox[:id].to_s if contact_inbox&.[](:id)
    headers['X-Chatwoot-Contact-Inbox-Verified'] = (contact_inbox&.[](:hmac_verified) || false).to_s
  end

  def format_response(raw_response_body)
    return raw_response_body if response_template.blank?

    response_data = parse_response_body(raw_response_body)
    render_template(response_template, { 'response' => response_data, 'r' => response_data })
  end

  private

  def render_template(template, context)
    liquid_template = Liquid::Template.parse(template, error_mode: :strict)
    liquid_template.render(context.deep_stringify_keys, registers: {}, strict_variables: true, strict_filters: true)
  rescue Liquid::SyntaxError, Liquid::UndefinedVariable, Liquid::UndefinedFilter => e
    Rails.logger.error("Liquid template error: #{e.message}")
    raise "Template rendering failed: #{e.message}"
  end

  def parse_response_body(body)
    JSON.parse(body)
  rescue JSON::ParserError
    body
  end
end
