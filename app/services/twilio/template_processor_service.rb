class Twilio::TemplateProcessorService
  pattr_initialize [:channel!, :template_params, :message]

  def call
    return [nil, nil] if template_params.blank?

    template = find_template
    return [nil, nil] if template.blank?

    content_variables = build_content_variables(template)
    [template['content_sid'], content_variables]
  end

  private

  def find_template
    channel.content_templates&.dig('templates')&.find do |template|
      template['friendly_name'] == template_params['name'] &&
        template['language'] == (template_params['language'] || 'en') &&
        template['status'] == 'approved'
    end
  end

  def build_content_variables(template)
    case template['template_type']
    when 'text', 'quick_reply', 'call_to_action'
      convert_text_template(template_params) # Text, quick reply and call-to-action templates use body variables
    when 'media'
      convert_media_template(template_params)
    else
      {}
    end
  end

  def convert_text_template(chatwoot_params)
    return process_key_value_params(chatwoot_params['processed_params']) if chatwoot_params['processed_params'].present?

    process_whatsapp_format_params(chatwoot_params['parameters'])
  end

  def process_key_value_params(processed_params)
    content_variables = {}
    processed_params.each do |key, value|
      content_variables[key.to_s] = value.to_s
    end
    content_variables
  end

  def process_whatsapp_format_params(parameters)
    content_variables = {}
    parameter_index = 1

    parameters&.each do |component|
      next unless component['type'] == 'body'

      component['parameters']&.each do |param|
        content_variables[parameter_index.to_s] = param['text']
        parameter_index += 1
      end
    end

    content_variables
  end

  def convert_media_template(chatwoot_params)
    content_variables = {}

    # Handle processed_params format (key-value pairs)
    if chatwoot_params['processed_params'].present?
      chatwoot_params['processed_params'].each do |key, value|
        content_variables[key.to_s] = value.to_s
      end
    else
      # Handle parameters format (WhatsApp Cloud API format)
      parameter_index = 1
      chatwoot_params['parameters']&.each do |component|
        parameter_index = process_component(component, content_variables, parameter_index)
      end
    end

    content_variables
  end

  def process_component(component, content_variables, parameter_index)
    case component['type']
    when 'header'
      process_media_header(component, content_variables, parameter_index)
    when 'body'
      process_body_parameters(component, content_variables, parameter_index)
    else
      parameter_index
    end
  end

  def process_media_header(component, content_variables, parameter_index)
    media_param = component['parameters']&.first
    return parameter_index unless media_param

    media_link = extract_media_link(media_param)
    if media_link
      content_variables[parameter_index.to_s] = media_link
      parameter_index + 1
    else
      parameter_index
    end
  end

  def extract_media_link(media_param)
    media_param.dig('image', 'link') ||
      media_param.dig('video', 'link') ||
      media_param.dig('document', 'link')
  end

  def process_body_parameters(component, content_variables, parameter_index)
    component['parameters']&.each do |param|
      content_variables[parameter_index.to_s] = param['text']
      parameter_index += 1
    end
    parameter_index
  end
end
