class Whatsapp::TemplateProcessorService
  pattr_initialize [:channel!, :template_params, :message]

  def call
    return [nil, nil, nil, nil] if template_params.blank?

    process_template_with_params
  end

  private

  def process_template_with_params
    [
      template_params['name'],
      template_params['namespace'],
      template_params['language'],
      processed_templates_params
    ]
  end

  def find_template
    channel.message_templates.find do |t|
      t['name'] == template_params['name'] &&
        t['language']&.downcase == template_params['language']&.downcase &&
        t['status']&.downcase == 'approved'
    end
  end

  def processed_templates_params
    template = find_template
    return if template.blank?

    # Convert legacy format to enhanced format before processing
    converter = Whatsapp::TemplateParameterConverterService.new(template_params, template)
    normalized_params = converter.normalize_to_enhanced

    process_enhanced_template_params(template, normalized_params['processed_params'])
  end

  def process_enhanced_template_params(template, processed_params = nil)
    processed_params ||= template_params['processed_params']
    components = []

    components.concat(process_header_components(processed_params))
    components.concat(process_body_components(processed_params, template))
    components.concat(process_footer_components(processed_params))
    components.concat(process_button_components(processed_params, template))

    @template_params = components
  end

  def process_header_components(processed_params)
    return [] if processed_params['header'].blank?

    header_data = upload_media_if_needed(processed_params['header'])
    header_params = build_header_params(header_data)
    header_params.present? ? [{ type: 'header', parameters: header_params }] : []
  end

  def upload_media_if_needed(header_data)
    return header_data unless header_data['media_url'].present? && header_data['media_type'].present?

    media_id = media_upload_service.upload_from_url(
      header_data['media_url'],
      content_type_for(header_data['media_type'])
    )

    return header_data if media_id.blank?

    header_data.merge('media_id' => media_id)
  end

  def content_type_for(media_type)
    { 'image' => 'image/jpeg', 'video' => 'video/mp4', 'document' => 'application/pdf' }[media_type.downcase]
  end

  def build_header_params(header_data)
    header_data.filter_map do |key, value|
      next if value.blank?

      build_single_header_param(key, value, header_data)
    end
  end

  def build_single_header_param(key, value, header_data)
    if key == 'media_url' && header_data['media_id'].present?
      parameter_builder.build_media_id_parameter(header_data['media_id'], header_data['media_type'], header_data['media_name'])
    elsif media_url_with_type?(key, header_data) && header_data['media_id'].blank?
      parameter_builder.build_media_parameter(value, header_data['media_type'], header_data['media_name'])
    elsif %w[media_type media_name media_id].exclude?(key)
      parameter_builder.build_parameter(value)
    end
  end

  def media_url_with_type?(key, header_data)
    key == 'media_url' && header_data['media_type'].present?
  end

  def process_body_components(processed_params, template)
    return [] if processed_params['body'].blank?

    body_params = processed_params['body'].filter_map do |key, value|
      next if value.blank?

      parameter_format = template['parameter_format']
      if parameter_format == 'NAMED'
        parameter_builder.build_named_parameter(key, value)
      else
        parameter_builder.build_parameter(value)
      end
    end

    body_params.present? ? [{ type: 'body', parameters: body_params }] : []
  end

  def process_footer_components(processed_params)
    return [] if processed_params['footer'].blank?

    footer_params = processed_params['footer'].filter_map do |_, value|
      next if value.blank?

      parameter_builder.build_parameter(value)
    end

    footer_params.present? ? [{ type: 'footer', parameters: footer_params }] : []
  end

  def process_button_components(processed_params, template = nil)
    if processed_params['buttons'].present?
      button_params = processed_params['buttons'].filter_map.with_index do |button, index|
        next if button.blank?

        if button['type']&.downcase == 'flow'
          build_flow_button_component(button, index)
        elsif button['type'] == 'url' || button['parameter'].present?
          {
            type: 'button',
            sub_type: button['type'] || 'url',
            index: index,
            parameters: [parameter_builder.build_button_parameter(button)]
          }
        end
      end

      return button_params.compact
    end

    # When no explicit button params provided, auto-include required FLOW button components
    # from the template definition — the WhatsApp API requires the button component for FLOW
    # templates even when there are no dynamic parameters.
    return [] if template.blank?

    buttons_component = template['components']&.find { |c| c['type'] == 'BUTTONS' }
    return [] if buttons_component.blank?

    buttons_component['buttons']&.filter_map&.with_index do |button, index|
      next unless button['type'] == 'FLOW'

      build_flow_button_component({}, index)
    end || []
  end

  def build_flow_button_component(button, index)
    params = []
    flow_token = button['parameter'].to_s.strip
    params = [parameter_builder.build_flow_button_parameter(flow_token)] if flow_token.present?

    {
      type: 'button',
      sub_type: 'flow',
      index: index,
      parameters: params
    }
  end

  def parameter_builder
    @parameter_builder ||= Whatsapp::PopulateTemplateParametersService.new
  end

  def media_upload_service
    @media_upload_service ||= Whatsapp::MediaUploadService.new(channel: channel)
  end
end
