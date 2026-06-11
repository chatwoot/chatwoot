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
    components.concat(process_button_components(processed_params))
    components.concat(process_flow_button_components(template, components))

    @template_params = components
  end

  def process_header_components(processed_params)
    return [] if processed_params['header'].blank?

    header_params = build_header_params(processed_params['header'])
    header_params.present? ? [{ type: 'header', parameters: header_params }] : []
  end

  def build_header_params(header_data)
    header_params = []
    header_data.each do |key, value|
      next if value.blank?

      if media_url_with_type?(key, header_data)
        media_name = header_data['media_name']
        media_param = parameter_builder.build_media_parameter(value, header_data['media_type'], media_name)
        header_params << media_param if media_param
      elsif key != 'media_type' && key != 'media_name'
        header_params << parameter_builder.build_parameter(value)
      end
    end
    header_params
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

  # Templates containing FLOW buttons require a button component carrying a
  # flow_token at send time — without it Meta rejects the message with error
  # 131009 ("Parameter value is not valid"), which made flow templates
  # impossible to send from the dashboard. We append the component
  # automatically from the template definition, so no UI changes are needed.
  # https://developers.facebook.com/docs/whatsapp/flows/guides/sendingaflow#templates
  def process_flow_button_components(template, existing_components)
    template_buttons = (template['components'] || []).select { |c| c['type'] == 'BUTTONS' }
                                                     .flat_map { |c| c['buttons'] || [] }
    template_buttons.each_with_index.filter_map do |button, index|
      next unless button['type'].to_s.casecmp('FLOW').zero?
      # Respect an explicit component if the caller already provided one for this index.
      next if existing_components.any? { |c| c[:type] == 'button' && c[:index] == index }

      {
        type: 'button',
        sub_type: 'flow',
        index: index,
        parameters: [{ type: 'action', action: { flow_token: flow_button_token } }]
      }
    end
  end

  # Unique, opaque token echoed back by Meta in the flow response (nfm_reply) —
  # embedding the conversation id lets flow endpoints correlate completions
  # with the originating conversation.
  def flow_button_token
    conversation_id = message&.conversation&.display_id
    "chatwoot_#{conversation_id || 'na'}_#{(Time.now.to_f * 1000).to_i}"
  end

  def parameter_builder
    @parameter_builder ||= Whatsapp::PopulateTemplateParametersService.new
  end
end
