class Whatsapp::TemplateCreatorService
  WHATSAPP_API_VERSION = 'v22.0'.freeze
  TEMPLATE_STATUS_PENDING = 'PENDING'.freeze
  DEFAULT_LANGUAGE = 'pt_BR'.freeze

  NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/
  BODY_MAX_LENGTH = 1024
  HEADER_MAX_LENGTH = 60
  FOOTER_MAX_LENGTH = 60
  BUTTON_TEXT_MAX_LENGTH = 25
  MAX_BUTTONS = 10

  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def create_template(params)
    errors = validate_params(params)
    return { success: false, errors: errors } if errors.any?

    prepared_params = prepare_template_params(params)
    return prepared_params.except(:params) unless prepared_params[:success]

    request_body = build_request_body(prepared_params[:params])
    response = submit_to_meta(request_body)
    process_response(response, params)
  end

  def update_template(template_id, params)
    return { success: false, error: 'Template ID is required' } if template_id.blank?

    errors = validate_params(params)
    return { success: false, errors: errors } if errors.any?

    prepared_params = prepare_template_params(params)
    return prepared_params.except(:params) unless prepared_params[:success]

    request_body = build_update_request_body(prepared_params[:params])
    response = submit_update_to_meta(template_id, request_body)
    process_response(response, params, fallback_template_id: template_id)
  end

  private

  def prepare_template_params(params)
    return { success: true, params: params } unless image_header?(params)
    return { success: true, params: params } if params[:header_handle].present?

    result = Whatsapp::TemplateMediaHeaderHandleService.new(@whatsapp_channel).generate(
      media_url: params[:header_media_url],
      file_name: params[:header_file_name]
    )
    return result unless result[:success]

    { success: true, params: params.merge(header_handle: result[:header_handle]) }
  end

  def validate_params(params)
    errors = []
    validate_required_fields(errors, params)
    validate_header(errors, params)
    validate_text_lengths(errors, params)
    validate_buttons(errors, params[:buttons])
    errors
  end

  def validate_required_fields(errors, params)
    errors << 'Name is required' if params[:name].blank?
    errors << 'Name must be snake_case (lowercase letters, numbers, underscores)' if params[:name].present? && !params[:name].match?(NAME_PATTERN)
    errors << 'Body text is required' if params[:body_text].blank?
  end

  def validate_header(errors, params)
    return if params[:header_format].blank?

    errors << 'Header format must be TEXT or IMAGE' unless %w[TEXT IMAGE].include?(params[:header_format].to_s.upcase)
    return unless image_header?(params)
    return unless params[:header_media_url].blank? && params[:header_handle].blank?

    errors << 'Header media URL is required for IMAGE headers'
  end

  def validate_text_lengths(errors, params)
    validate_max_length(errors, 'Body text', params[:body_text], BODY_MAX_LENGTH)
    validate_max_length(errors, 'Header text', params[:header_text], HEADER_MAX_LENGTH)
    validate_max_length(errors, 'Footer text', params[:footer_text], FOOTER_MAX_LENGTH)
  end

  def validate_buttons(errors, buttons)
    return if buttons.blank?

    errors << "Maximum #{MAX_BUTTONS} buttons allowed" if buttons.length > MAX_BUTTONS
    buttons.each_with_index do |btn, idx|
      validate_max_length(errors, "Button #{idx + 1} text", btn[:text], BUTTON_TEXT_MAX_LENGTH)
    end
  end

  def validate_max_length(errors, label, value, max_length)
    return if value.blank? || value.length <= max_length

    errors << "#{label} exceeds #{max_length} characters"
  end

  def build_request_body(params)
    request_body = {
      name: params[:name],
      language: params[:language].presence || DEFAULT_LANGUAGE,
      category: params[:category].presence || 'UTILITY',
      components: build_components(params)
    }
    parameter_format = params[:parameter_format].presence || inferred_parameter_format(params)
    request_body[:parameter_format] = parameter_format if parameter_format.present?
    request_body[:allow_category_change] = params[:allow_category_change] unless params[:allow_category_change].nil?
    request_body
  end

  def build_components(params)
    components_builder.build(params)
  end

  def build_update_request_body(params)
    request_body = build_request_body(params).slice(:category, :components, :parameter_format)
    request_body[:category] = params[:category].presence || 'UTILITY'
    request_body
  end

  def inferred_parameter_format(params)
    components_builder.inferred_parameter_format(params)
  end

  def image_header?(params)
    params[:header_format].to_s.upcase == 'IMAGE'
  end

  def components_builder
    @components_builder ||= Whatsapp::TemplateComponentsBuilder.new
  end

  def submit_to_meta(request_body)
    HTTParty.post(
      "#{business_account_path}/message_templates",
      headers: api_headers,
      body: request_body.to_json
    )
  end

  def submit_update_to_meta(template_id, request_body)
    HTTParty.post(
      "#{api_base_path}/#{WHATSAPP_API_VERSION}/#{template_id}",
      headers: api_headers,
      body: request_body.to_json
    )
  end

  def process_response(response, params, fallback_template_id: nil)
    if response.success?
      {
        success: true,
        template_id: response['id'] || fallback_template_id,
        template_name: params[:name],
        language: params[:language].presence || DEFAULT_LANGUAGE,
        category: response['category'] || params[:category],
        parameter_format: response['parameter_format'] || params[:parameter_format],
        status: TEMPLATE_STATUS_PENDING
      }
    else
      Rails.logger.error "WhatsApp template creation failed: #{response.code} - #{response.body}"
      Whatsapp::TemplateMetaErrorDetails.from(response).merge(
        success: false,
        response_code: response.code
      )
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
