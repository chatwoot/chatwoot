module Concerns::Toolable
  extend ActiveSupport::Concern

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

  def format_response(raw_response_body)
    return raw_response_body if response_template.blank?

    response_data = parse_response_body(raw_response_body)
    render_template(response_template, { 'response' => response_data })
  end

  private

  def render_template(template, context)
    Liquid::Template.parse(template).render(context.deep_stringify_keys)
  end

  def parse_response_body(body)
    JSON.parse(body)
  rescue JSON::ParserError
    body
  end
end
