require 'cgi'

class Whatsapp::MessageTemplateService
  WHATSAPP_API_VERSION = 'v23.0'.freeze
  ALLOWED_CATEGORIES = %w[MARKETING UTILITY].freeze
  ALLOWED_HEADER_FORMATS = %w[TEXT IMAGE VIDEO DOCUMENT].freeze
  MAX_EXAMPLE_VALUE_LENGTH = 1024
  HTTP_TIMEOUT = 120 # 2 minutes timeout for Meta API requests

  # Template limits
  LIMITS = {
    NAME_MAX: 512,
    HEADER_TEXT_MAX: 60,
    HEADER_MAX_VARIABLES: 1,
    BODY_MAX: 1024,
    FOOTER_MAX: 60
  }.freeze

  # Supported WhatsApp template languages (based on Meta's official documentation)
  ALLOWED_LANGUAGES = %w[
    af sq ar az bn bg ca zh_CN zh_HK zh_TW hr cs da nl
    en en_GB en_US et fil fi fr ka de el gu ha he hi hu
    id ga it ja kn kk rw_RW ko ky_KG lo lv lt mk ms ml mr
    nb fa pl pt_BR pt_PT pa ro ru sr sk sl es es_AR es_ES
    es_MX sw sv ta te th tr uk ur uz vi zu
  ].freeze

  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def create_template(params)
    validate_template_params!(params)
    request_body = build_template_request_body(params)
    response = send_template_creation_request(request_body)
    process_template_creation_response(response, params)
  end

  def list_templates(options = {})
    limit = options[:limit] || 20
    after_cursor = options[:after]
    before_cursor = options[:before]
    fetch_all = options[:fetch_all] || false

    if fetch_all
      fetch_all_templates
    else
      fetch_templates_page(limit: limit, after: after_cursor, before: before_cursor)
    end
  rescue StandardError => e
    Rails.logger.error "Error listing templates: #{e.message}"
    { success: false, error: e.message }
  end

  def fetch_templates_page(limit:, after: nil, before: nil)
    query_params = { limit: limit }
    query_params[:after] = after if after.present?
    query_params[:before] = before if before.present?

    url = "#{business_account_path}/message_templates?#{query_params.to_query}"
    response = HTTParty.get(url, headers: api_headers, timeout: HTTP_TIMEOUT)

    if response.success?
      paging = response['paging'] || {}
      cursors = paging['cursors'] || {}

      {
        success: true,
        templates: response['data'] || [],
        paging: {
          cursors: {
            before: cursors['before'],
            after: cursors['after']
          },
          has_next: paging['next'].present?,
          has_previous: paging['previous'].present?
        }
      }
    else
      {
        success: false,
        error: parse_error_message(response.body)
      }
    end
  end

  def fetch_all_templates
    all_templates = []
    after_cursor = nil
    max_iterations = 60 # Safety limit: 60 pages * 100 = 6,000 templates (Meta's max limit)

    max_iterations.times do
      result = fetch_templates_page(limit: 100, after: after_cursor)

      unless result[:success]
        return result # Return error if any page fails
      end

      all_templates.concat(result[:templates])

      # Check if there are more pages
      break unless result[:paging][:has_next]

      after_cursor = result[:paging][:cursors][:after]
      break if after_cursor.blank?
    end

    {
      success: true,
      templates: all_templates,
      paging: {
        cursors: { before: nil, after: nil },
        has_next: false,
        has_previous: false
      }
    }
  end

  def get_template_status(template_name)
    encoded_name = CGI.escape(template_name.to_s)
    response = HTTParty.get(
      "#{business_account_path}/message_templates?name=#{encoded_name}",
      headers: api_headers,
      timeout: HTTP_TIMEOUT
    )

    if response.success? && response['data']&.any?
      template_data = response['data'].first
      {
        success: true,
        template: {
          id: template_data['id'],
          name: template_data['name'],
          status: template_data['status'],
          language: template_data['language'],
          category: template_data['category'],
          components: template_data['components']
        }
      }
    else
      { success: false, error: 'Template not found' }
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching template status: #{e.message}"
    { success: false, error: e.message }
  end

  def delete_template(template_name, template_id = nil)
    encoded_name = CGI.escape(template_name.to_s)

    # Build delete URL - Meta API requires both name and hsm_id for reliable deletion
    delete_url = "#{business_account_path}/message_templates?name=#{encoded_name}"
    if template_id.present?
      encoded_id = CGI.escape(template_id.to_s)
      delete_url += "&hsm_id=#{encoded_id}"
    end

    response = HTTParty.delete(delete_url, headers: api_headers, timeout: HTTP_TIMEOUT)

    if response.success?
      { success: true }
    else
      error_info = parse_error_details(response.body)
      {
        success: false,
        error: error_info[:message],
        code: error_info[:code]
      }
    end
  rescue StandardError => e
    Rails.logger.error "Error deleting template: #{e.message}"
    { success: false, error: e.message }
  end

  def parse_error_details(response_body)
    return { message: 'Unknown error', code: nil } if response_body.blank?

    begin
      error_data = JSON.parse(response_body)
      whatsapp_error = error_data['error'] || {}
      {
        message: whatsapp_error['error_user_msg'] || whatsapp_error['message'] || 'Template operation failed',
        code: whatsapp_error['code']
      }
    rescue JSON::ParserError
      { message: 'Template operation failed', code: nil }
    end
  end

  private

  def validate_template_params!(params)
    # Required fields
    raise ArgumentError, 'Template name is required' if params[:name].blank?
    raise ArgumentError, 'Template language is required' if params[:language].blank?
    raise ArgumentError, 'Template category is required' if params[:category].blank?
    raise ArgumentError, 'Body text is required' if params.dig(:body, :text).blank?

    # Name validation
    if params[:name].to_s.length > LIMITS[:NAME_MAX]
      raise ArgumentError, "Template name cannot exceed #{LIMITS[:NAME_MAX]} characters"
    end

    # Category validation
    unless ALLOWED_CATEGORIES.include?(params[:category])
      raise ArgumentError, "Category must be one of: #{ALLOWED_CATEGORIES.join(', ')}"
    end

    # Language validation
    unless ALLOWED_LANGUAGES.include?(params[:language])
      raise ArgumentError, "Invalid language code: #{params[:language]}"
    end

    # Header validation
    validate_header!(params[:header]) if params[:header].present?

    # Body validation
    validate_body!(params[:body])

    # Footer validation
    validate_footer!(params[:footer]) if params[:footer].present?
  end

  def validate_header!(header)
    return if header.blank? || header[:format].blank?

    unless ALLOWED_HEADER_FORMATS.include?(header[:format])
      raise ArgumentError, "Header format must be one of: #{ALLOWED_HEADER_FORMATS.join(', ')}"
    end

    # Text header validation
    if header[:format] == 'TEXT' && header[:text].present?
      header_text = header[:text].to_s

      # Check max variables in header
      variables_count = header_text.scan(/\{\{[^}]+\}\}/).length
      if variables_count > LIMITS[:HEADER_MAX_VARIABLES]
        raise ArgumentError, "Header can only contain #{LIMITS[:HEADER_MAX_VARIABLES]} variable"
      end

      # Validate raw text length (without variable replacement)
      if header_text.length > LIMITS[:HEADER_TEXT_MAX]
        raise ArgumentError, "Header text cannot exceed #{LIMITS[:HEADER_TEXT_MAX]} characters (current: #{header_text.length})"
      end

      # Validate variables count matches examples count
      validate_variables_match_examples!(header_text, header[:examples], 'Header')

      # Validate rendered length (with variables replaced by examples)
      rendered_length = calculate_rendered_length(header_text, header[:examples])
      if rendered_length > LIMITS[:HEADER_TEXT_MAX]
        raise ArgumentError, "Header text with variable values cannot exceed #{LIMITS[:HEADER_TEXT_MAX]} characters (current: #{rendered_length})"
      end
    end
  end

  def validate_body!(body)
    return if body.blank?

    body_text = body[:text].to_s

    # Validate raw text length (without variable replacement)
    if body_text.length > LIMITS[:BODY_MAX]
      raise ArgumentError, "Body text cannot exceed #{LIMITS[:BODY_MAX]} characters (current: #{body_text.length})"
    end

    # Validate variables count matches examples count
    validate_variables_match_examples!(body_text, body[:examples], 'Body')

    # Validate rendered length (with variables replaced by examples)
    rendered_length = calculate_rendered_length(body_text, body[:examples])
    if rendered_length > LIMITS[:BODY_MAX]
      raise ArgumentError, "Body text with variable values cannot exceed #{LIMITS[:BODY_MAX]} characters (current: #{rendered_length})"
    end
  end

  def validate_footer!(footer)
    return if footer.blank? || footer[:text].blank?

    # Footer cannot contain variables
    if footer[:text].to_s.include?('{{')
      raise ArgumentError, 'Footer cannot contain variables'
    end

    if footer[:text].to_s.length > LIMITS[:FOOTER_MAX]
      raise ArgumentError, "Footer text cannot exceed #{LIMITS[:FOOTER_MAX]} characters"
    end
  end

  def validate_variables_match_examples!(text, examples, field_name)
    return if text.blank?

    # Extract unique variables from text
    variables = text.scan(/\{\{([^}]+)\}\}/).flatten.uniq
    variables_count = variables.length

    # If no variables, no examples needed
    return if variables_count.zero?

    # Count provided examples
    examples_hash = (examples || {}).transform_keys(&:to_s)
    examples_count = examples_hash.keys.length

    # Check if counts match
    if variables_count != examples_count
      raise ArgumentError, "#{field_name} has #{variables_count} variable(s) but #{examples_count} example(s) provided. Each variable must have an example value."
    end

    # Check if all variables have corresponding examples
    missing_examples = variables.reject { |var| examples_hash.key?(var) }

    if missing_examples.any?
      raise ArgumentError, "#{field_name} is missing example values for: #{missing_examples.map { |v| "{{#{v}}}" }.join(', ')}"
    end

    # Check that no example value contains a self-reference
    validate_no_self_reference!(examples_hash, field_name)
  end

  def validate_no_self_reference!(examples_hash, field_name)
    examples_hash.each do |var_name, example_value|
      next if example_value.blank?

      # Check if the example value contains a reference to itself
      self_reference_pattern = /\{\{#{Regexp.escape(var_name)}\}\}/
      if example_value.to_s.match?(self_reference_pattern)
        raise ArgumentError, "#{field_name} example for {{#{var_name}}} cannot reference itself"
      end
    end
  end

  def calculate_rendered_length(text, examples = nil)
    return text.length if text.blank?

    rendered_text = text.dup
    examples_hash = (examples || {}).transform_keys(&:to_s)

    # Find all variables in the text
    variables = text.scan(/\{\{([^}]+)\}\}/).flatten

    variables.each do |var|
      placeholder = "{{#{var}}}"
      # Use the example value if provided, otherwise use the variable name as fallback
      replacement = examples_hash[var] || var
      rendered_text = rendered_text.sub(placeholder, replacement.to_s)
    end

    rendered_text.length
  end

  def build_template_request_body(params)
    {
      name: sanitize_template_name(params[:name]),
      language: params[:language],
      category: params[:category],
      components: build_components(params)
    }
  end

  def sanitize_template_name(name)
    # WhatsApp template names must be lowercase and use underscores
    name.to_s.downcase.gsub(/[^a-z0-9_]/, '_').gsub(/_+/, '_').gsub(/^_|_$/, '')
  end

  def build_components(params)
    components = []

    # Header component (optional)
    if params[:header].present?
      components << build_header_component(params[:header])
    end

    # Body component (required)
    components << build_body_component(params[:body])

    # Footer component (optional)
    if params[:footer].present? && params[:footer][:text].present?
      components << build_footer_component(params[:footer])
    end

    components.compact
  end

  def build_header_component(header)
    return nil if header.blank? || header[:format].blank?

    component = {
      type: 'HEADER',
      format: header[:format]
    }

    case header[:format]
    when 'TEXT'
      component[:text] = header[:text] if header[:text].present?
      # Add example for text with variables
      if header[:text]&.include?('{{')
        example_values = extract_example_values_from_text(header[:text], header[:examples])
        component[:example] = { header_text: example_values } if example_values.any?
      end
    when 'IMAGE', 'VIDEO', 'DOCUMENT'
      if header[:example_url].present? && valid_media_url?(header[:example_url])
        component[:example] = { header_handle: [header[:example_url]] }
      end
    end

    component
  end

  def build_body_component(body)
    component = {
      type: 'BODY',
      text: body[:text]
    }

    # Add example values for variables in body
    if body[:text]&.include?('{{')
      example_values = extract_example_values_from_text(body[:text], body[:examples])
      component[:example] = { body_text: [example_values] } if example_values.any?
    end

    component
  end

  def build_footer_component(footer)
    {
      type: 'FOOTER',
      text: footer[:text]
    }
  end

  def extract_example_values_from_text(text, provided_examples = nil)
    # Extract variable placeholders like {{1}}, {{2}}, {{variable_name}}, etc.
    variables = text.scan(/\{\{([^}]+)\}\}/).flatten.uniq

    # Sort numeric variables, keep named ones in order of appearance
    numeric_vars = variables.select { |v| v.match?(/^\d+$/) }.sort_by(&:to_i)
    named_vars = variables.reject { |v| v.match?(/^\d+$/) }
    sorted_variables = numeric_vars + named_vars

    # Map to example values, using provided examples or generating placeholders
    # Sanitize: ensure all values are strings with reasonable length
    examples_hash = (provided_examples || {}).transform_keys(&:to_s).transform_values do |v|
      sanitize_example_value(v)
    end

    sorted_variables.map do |var|
      examples_hash[var] || "example_#{var}"
    end
  end

  def sanitize_example_value(value)
    # Ensure value is a string and truncate if too long
    str_value = value.to_s.strip
    str_value.length > MAX_EXAMPLE_VALUE_LENGTH ? str_value[0...MAX_EXAMPLE_VALUE_LENGTH] : str_value
  end

  def valid_media_url?(url)
    return false if url.blank?

    uri = URI.parse(url.to_s)
    uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    false
  end

  def send_template_creation_request(request_body)
    HTTParty.post(
      "#{business_account_path}/message_templates",
      headers: api_headers,
      body: request_body.to_json,
      timeout: HTTP_TIMEOUT
    )
  end

  def process_template_creation_response(response, params)
    if response.success?
      {
        success: true,
        template: {
          id: response['id'],
          name: sanitize_template_name(params[:name]),
          status: 'PENDING',
          language: params[:language],
          category: params[:category]
        }
      }
    else
      Rails.logger.error "WhatsApp template creation failed: #{response.code} - #{response.body}"
      {
        success: false,
        error: parse_error_message(response.body),
        response_body: response.body
      }
    end
  end

  def parse_error_message(response_body)
    return 'Unknown error' if response_body.blank?

    begin
      error_data = JSON.parse(response_body)
      whatsapp_error = error_data['error'] || {}
      whatsapp_error['error_user_msg'] || whatsapp_error['message'] || 'Template operation failed'
    rescue JSON::ParserError
      'Template operation failed'
    end
  end

  def business_account_path
    "#{api_base_path}/#{WHATSAPP_API_VERSION}/#{@whatsapp_channel.provider_config['business_account_id']}"
  end

  def api_headers
    {
      'Authorization' => "Bearer #{@whatsapp_channel.provider_config['api_key']}",
      'Content-Type' => 'application/json'
    }
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
