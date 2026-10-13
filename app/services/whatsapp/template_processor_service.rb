class Whatsapp::TemplateProcessorService
  ValidationError = Whatsapp::TemplateParameterValidationService::ValidationError

  pattr_initialize [:channel!, :template_params, :message]

  def call
    return [nil, nil, nil, nil] if template_params.blank?
    return process_cloud_template if channel.provider == 'whatsapp_cloud'

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

  def process_cloud_template
    template = find_exact_cloud_template
    raise ValidationError, 'Template is not an approved synchronized template' if template.blank?

    classifier = Whatsapp::TemplateClassifierService.new(template)
    raise ValidationError, "Template cannot be sent: #{classifier.classification_reason}" unless classifier.sendable?

    normalized_params = normalized_processed_params(template)
    Whatsapp::TemplateParameterValidationService.new(
      template: template,
      requirements: classifier.parameter_requirements,
      processed_params: normalized_params
    ).call

    [template['name'], template['namespace'], template['language'], process_enhanced_template_params(template, normalized_params)]
  rescue ArgumentError => e
    raise ValidationError, e.message
  end

  def find_exact_cloud_template
    Array(channel.message_templates).find do |template|
      template['name'] == template_params['name'] &&
        template['language'] == template_params['language'] &&
        template['status'].to_s.casecmp('approved').zero?
    end
  end

  def normalized_processed_params(template)
    params = template_params.deep_dup
    Whatsapp::TemplateParameterConverterService.new(params, template).normalize_to_enhanced.fetch('processed_params', {}) || {}
  rescue ArgumentError => e
    raise ValidationError, e.message
  end

  def find_template
    channel.message_templates.find do |t|
      t['name'].to_s.casecmp?(template_params['name'].to_s) &&
        t['language'].to_s.casecmp?(template_params['language'].to_s) &&
        t['status'].to_s.casecmp?('approved')
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
    components.concat(process_button_components(processed_params, template))

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
    header_parameters = header_data
    header_parameters = header_parameters.sort_by { |key, _value| key.to_i } unless template['parameter_format'] == 'NAMED'

    header_parameters.filter_map do |key, value|
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

  def process_button_components(processed_params, template = nil)
    return [] if processed_params['buttons'].blank?

    buttons = processed_params['buttons']
    dynamic_indexes = dynamic_button_indexes(template)
    sparse_buttons = buttons.any?(&:blank?)
    button_params = buttons.filter_map.with_index do |button, index|
      next if button.blank?

      build_button_component(button, index, dynamic_indexes, sparse_buttons)
    end

    button_params.compact
  end

  def build_button_component(button, index, dynamic_indexes, sparse_buttons)
    return unless button['type'] == 'url' || button['parameter'].present?

    {
      type: 'button',
      sub_type: button['type'] || 'url',
      index: provider_button_index(index, dynamic_indexes, sparse_buttons),
      parameters: [parameter_builder.build_button_parameter(button)]
    }
  end

  def provider_button_index(index, dynamic_indexes, sparse_buttons)
    return index unless channel.provider == 'whatsapp_cloud'
    return index if sparse_buttons

    dynamic_indexes.fetch(index, index)
  end

  def dynamic_button_indexes(template)
    return [] if template.blank?

    buttons_component = Array(template['components']).find { |component| component['type'].to_s.upcase == 'BUTTONS' }
    Array(buttons_component&.dig('buttons')).filter_map.with_index do |button, index|
      index if dynamic_button?(button)
    end
  end

  def dynamic_button?(button)
    type = button['type'].to_s.upcase
    type == 'COPY_CODE' || (type == 'URL' && button['url'].to_s.match?(/{{[^{}]+}}/))
  end

  def parameter_builder
    @parameter_builder ||= Whatsapp::PopulateTemplateParametersService.new
  end
end
