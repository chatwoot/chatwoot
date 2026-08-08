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

    components.concat(process_header_components(processed_params, template))
    components.concat(process_body_components(processed_params, template))
    components.concat(process_footer_components(processed_params))
    components.concat(process_button_components(processed_params))

    @template_params = components
  end

  def process_header_components(processed_params, template)
    return [] if processed_params['header'].blank?

    header_params = build_header_params(processed_params['header'], template)
    header_params.present? ? [{ type: 'header', parameters: header_params }] : []
  end

  def build_header_params(header_data, template)
    header_component = template['components']&.find { |component| component['type'] == 'HEADER' }
    return build_text_header_params(header_data, template) if header_component&.dig('format') == 'TEXT'

    build_media_header_params(header_data)
  end

  def build_text_header_params(header_data, template)
    header_data.filter_map do |key, value|
      build_text_parameter(key, value, template) if value.present?
    end
  end

  def build_media_header_params(header_data)
    return [] if header_data['media_url'].blank? || header_data['media_type'].blank?

    media_param = parameter_builder.build_media_parameter(header_data['media_url'], header_data['media_type'], header_data['media_name'])
    media_param ? [media_param] : []
  end

  def process_body_components(processed_params, template)
    return [] if processed_params['body'].blank?

    body_parameters = processed_params['body']
    body_parameters = body_parameters.sort_by { |key, _value| key.to_i } unless template['parameter_format'] == 'NAMED'

    body_params = body_parameters.filter_map do |key, value|
      next if value.blank?

      build_text_parameter(key, value, template)
    end

    body_params.present? ? [{ type: 'body', parameters: body_params }] : []
  end

  def build_text_parameter(key, value, template)
    return parameter_builder.build_named_parameter(key, value) if template['parameter_format'] == 'NAMED'

    parameter_builder.build_parameter(value)
  end

  def process_footer_components(processed_params)
    return [] if processed_params['footer'].blank?

    footer_params = processed_params['footer'].filter_map do |_, value|
      next if value.blank?

      parameter_builder.build_parameter(value)
    end

    footer_params.present? ? [{ type: 'footer', parameters: footer_params }] : []
  end

  def process_button_components(processed_params)
    return [] if processed_params['buttons'].blank?

    button_params = processed_params['buttons'].filter_map.with_index do |button, index|
      next if button.blank?

      if button['type'] == 'url' || button['parameter'].present?
        {
          type: 'button',
          sub_type: button['type'] || 'url',
          index: index,
          parameters: [parameter_builder.build_button_parameter(button)]
        }
      end
    end

    button_params.compact
  end

  def parameter_builder
    @parameter_builder ||= Whatsapp::PopulateTemplateParametersService.new
  end
end
