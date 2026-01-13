module Concerns::Toolable
  extend ActiveSupport::Concern

  def tool(assistant)
    custom_tool_record = self
    # Convert slug to valid Ruby constant name (replace hyphens with underscores, then camelize)
    class_name = custom_tool_record.slug.underscore.camelize

    # Always create a fresh class to reflect current metadata
    tool_class = Class.new(Captain::Tools::HttpTool) do
      description custom_tool_record.description

      custom_tool_record.param_schema.each do |param_def|
        param param_def['name'].to_sym,
              type: param_def['type'],
              desc: param_def['description'],
              required: param_def.fetch('required', true)
      end
    end

    # Register the dynamically created class as a constant in the Captain::Tools namespace.
    # This is required because RubyLLM's Tool base class derives the tool name from the class name
    # (via Class#name). Anonymous classes created with Class.new have no name and return empty strings,
    # which causes "Invalid 'tools[].function.name': empty string" errors from the LLM API.
    # By setting it as a constant, the class gets a proper name (e.g., "Captain::Tools::CatFactLookup")
    # which RubyLLM extracts and normalizes to "cat-fact-lookup" for the LLM API.
    # We refresh the constant on each call to ensure tool metadata changes are reflected.
    Captain::Tools.send(:remove_const, class_name) if Captain::Tools.const_defined?(class_name, false)
    Captain::Tools.const_set(class_name, tool_class)

    tool_class.new(assistant, self)
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
      if auth_config['location'] == 'header'
        { auth_config['name'] => auth_config['key'] }
      else
        {}
      end
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
