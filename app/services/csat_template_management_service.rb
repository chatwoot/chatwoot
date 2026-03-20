class CsatTemplateManagementService # rubocop:disable Metrics/ClassLength
  DEFAULT_BUTTON_TEXT = 'Please rate us'.freeze
  DEFAULT_LANGUAGE = 'en'.freeze

  def initialize(inbox)
    @inbox = inbox
  end

  def template_status
    template = @inbox.csat_config&.dig('template')
    return { template_exists: false } unless template

    if @inbox.twilio_whatsapp?
      get_twilio_template_status(template)
    else
      get_whatsapp_template_status(template)
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching CSAT template status: #{e.message}"
    { service_error: e.message }
  end

  def create_template(template_params)
    validate_template_params!(template_params)

    delete_existing_template_if_needed

    result = create_template_via_provider(template_params)
    update_inbox_csat_config(result, source: 'auto_created') if result[:success]

    result
  rescue StandardError => e
    Rails.logger.error "Error creating CSAT template: #{e.message}"
    { success: false, service_error: 'Template creation failed' }
  end

  def link_existing_template(template_name, language, body_variables: {})
    raise ArgumentError, 'Template name is required' if template_name.blank?
    raise ArgumentError, 'Only WhatsApp Cloud channels are supported' unless whatsapp_cloud_channel?

    csat_service = Whatsapp::CsatTemplateService.new(@inbox.channel)
    status_result = csat_service.get_template_status(template_name)
    raise ArgumentError, 'Template not found on Meta' unless status_result[:success]

    template_data = find_template_in_synced(template_name)
    validate_synced_template!(csat_service, template_data, body_variables)

    delete_existing_template_if_needed

    save_linked_template(template_name, language, status_result, body_variables: body_variables)
  rescue ArgumentError => e
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "Error linking existing CSAT template: #{e.message}"
    { success: false, service_error: 'Failed to link template' }
  end

  def available_templates
    raise ArgumentError, 'Only WhatsApp Cloud channels are supported' unless whatsapp_cloud_channel?

    Whatsapp::CsatTemplateService.new(@inbox.channel).available_csat_templates
  rescue ArgumentError
    []
  rescue StandardError => e
    Rails.logger.error "Error fetching available CSAT templates: #{e.message}"
    []
  end

  private

  def whatsapp_cloud_channel?
    @inbox.whatsapp? && @inbox.channel&.provider == 'whatsapp_cloud'
  end

  def validate_body_variables!(required_variables, body_variables)
    return if required_variables.blank?

    missing = required_variables.select { |key| body_variables[key].blank? }
    raise ArgumentError, "All body variables must be set. Missing: #{missing.join(', ')}" if missing.any?
  end

  def validate_synced_template!(csat_service, template_data, body_variables)
    raise ArgumentError, 'Template not found in synced templates. Please sync templates first.' if template_data.blank?

    unless csat_service.valid_csat_template?(template_data)
      raise ArgumentError, 'Template is not compatible with CSAT surveys. It must have a URL button with a dynamic parameter.'
    end

    body_text = template_data['components']&.find { |c| c['type'] == 'BODY' }&.dig('text')
    validate_body_variables!(csat_service.extract_body_variables(body_text), body_variables)
  end

  def validate_template_params!(template_params)
    raise ActionController::ParameterMissing, 'message' if template_params[:message].blank?
  end

  def create_template_via_provider(template_params)
    if @inbox.twilio_whatsapp?
      create_twilio_template(template_params)
    else
      create_whatsapp_template(template_params)
    end
  end

  def create_twilio_template(template_params)
    template_config = build_template_config(template_params)
    template_service = Twilio::CsatTemplateService.new(@inbox.channel)
    template_service.create_template(template_config)
  end

  def create_whatsapp_template(template_params)
    template_config = build_template_config(template_params)
    Whatsapp::CsatTemplateService.new(@inbox.channel).create_template(template_config)
  end

  def build_template_config(template_params)
    {
      message: template_params[:message],
      button_text: template_params[:button_text] || DEFAULT_BUTTON_TEXT,
      base_url: ENV.fetch('FRONTEND_URL', 'http://localhost:3000'),
      language: template_params[:language] || DEFAULT_LANGUAGE,
      template_name: CsatTemplateNameService.csat_template_name(@inbox.id)
    }
  end

  def find_template_in_synced(template_name)
    @inbox.channel.message_templates&.find { |t| t['name'] == template_name }
  end

  def save_linked_template(template_name, language, status_result, body_variables: {})
    current_config = @inbox.csat_config || {}
    template_data = {
      'name' => template_name,
      'template_id' => status_result.dig(:template, :id),
      'language' => language || status_result.dig(:template, :language) || 'en',
      'source' => 'user_selected',
      'linked_at' => Time.current.iso8601
    }
    template_data['body_variables'] = body_variables if body_variables.present?
    @inbox.update!(csat_config: current_config.merge('template' => template_data))

    {
      success: true,
      template_name: template_name,
      template_id: template_data['template_id'],
      language: template_data['language'],
      status: status_result.dig(:template, :status),
      source: 'user_selected',
      linked_at: template_data['linked_at']
    }
  end

  def update_inbox_csat_config(result, source: 'auto_created')
    current_config = @inbox.csat_config || {}
    template_data = build_template_data_from_result(result).merge('source' => source)
    updated_config = current_config.merge('template' => template_data)
    @inbox.update!(csat_config: updated_config)
  end

  def build_template_data_from_result(result)
    if @inbox.twilio_whatsapp?
      build_twilio_template_data(result)
    else
      build_whatsapp_cloud_template_data(result)
    end
  end

  def build_twilio_template_data(result)
    {
      'friendly_name' => result[:friendly_name],
      'content_sid' => result[:content_sid],
      'approval_sid' => result[:approval_sid],
      'language' => result[:language],
      'status' => result[:whatsapp_status] || result[:status],
      'created_at' => Time.current.iso8601
    }.compact
  end

  def build_whatsapp_cloud_template_data(result)
    {
      'name' => result[:template_name],
      'template_id' => result[:template_id],
      'language' => result[:language],
      'created_at' => Time.current.iso8601
    }
  end

  def get_twilio_template_status(template)
    content_sid = template['content_sid']
    return { template_exists: false } unless content_sid

    template_service = Twilio::CsatTemplateService.new(@inbox.channel)
    status_result = template_service.get_template_status(content_sid)
    return { template_exists: false, error: 'Template not found' } unless status_result.is_a?(Hash)

    if status_result[:success]
      {
        template_exists: true,
        friendly_name: template['friendly_name'],
        content_sid: template['content_sid'],
        status: status_result[:template][:status],
        language: template['language']
      }
    else
      {
        template_exists: false,
        error: 'Template not found'
      }
    end
  end

  def get_whatsapp_template_status(template)
    template_name = template['name'] || CsatTemplateNameService.csat_template_name(@inbox.id)
    status_result = Whatsapp::CsatTemplateService.new(@inbox.channel).get_template_status(template_name)
    return { template_exists: false, error: 'Template not found' } unless status_result.is_a?(Hash)

    if status_result[:success]
      {
        template_exists: true,
        template_name: template_name,
        status: status_result[:template][:status],
        template_id: status_result[:template][:id]
      }
    else
      {
        template_exists: false,
        error: 'Template not found'
      }
    end
  end

  def delete_existing_template_if_needed
    template = @inbox.csat_config&.dig('template')
    return true if template.blank?
    return true if template['source'] == 'user_selected'

    if @inbox.twilio_whatsapp?
      delete_existing_twilio_template(template)
    else
      delete_existing_whatsapp_template(template)
    end
  rescue StandardError => e
    Rails.logger.error "Error during template deletion for inbox #{@inbox.id}: #{e.message}"
    false
  end

  def delete_existing_twilio_template(template)
    content_sid = template['content_sid']
    return true if content_sid.blank?

    template_service = Twilio::CsatTemplateService.new(@inbox.channel)
    deletion_result = template_service.delete_template(nil, content_sid)

    if deletion_result[:success]
      Rails.logger.info "Deleted existing Twilio CSAT template '#{content_sid}' for inbox #{@inbox.id}"
      true
    else
      Rails.logger.warn "Failed to delete existing Twilio CSAT template '#{content_sid}' for inbox #{@inbox.id}: #{deletion_result[:response_body]}"
      false
    end
  end

  def delete_existing_whatsapp_template(template)
    template_name = template['name']
    return true if template_name.blank?

    csat_template_service = Whatsapp::CsatTemplateService.new(@inbox.channel)
    template_status = csat_template_service.get_template_status(template_name)
    return true unless template_status[:success]

    deletion_result = csat_template_service.delete_template(template_name)
    if deletion_result[:success]
      Rails.logger.info "Deleted existing CSAT template '#{template_name}' for inbox #{@inbox.id}"
      true
    else
      Rails.logger.warn "Failed to delete existing CSAT template '#{template_name}' for inbox #{@inbox.id}: #{deletion_result[:response_body]}"
      false
    end
  end
end
