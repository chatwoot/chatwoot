class Whatsapp::LiquidTemplateProcessorService
  pattr_initialize [:campaign!, :contact!]

  def process_template_params(template_params)
    return template_params if template_params.blank?

    template_params_copy = deep_copy(template_params)
    processed_params = template_params_copy['processed_params']

    return template_params_copy if processed_params.blank?

    process_body_params(processed_params)
    process_header_params(processed_params)
    process_button_params(processed_params)
    process_footer_params(processed_params)

    template_params_copy
  end

  private

  def process_body_params(processed_params)
    return if processed_params['body'].blank?

    processed_params['body'].each do |key, value|
      processed_params['body'][key] = process_liquid(value) if value.is_a?(String)
    end
  end

  def process_header_params(processed_params)
    return if processed_params['header'].blank?

    processed_params['header'].each do |key, value|
      processed_params['header'][key] = process_liquid(value) if value.is_a?(String)
    end
  end

  def process_button_params(processed_params)
    return if processed_params['buttons'].blank?

    processed_params['buttons'].each do |button|
      next if button.blank?

      button['parameter'] = process_liquid(button['parameter']) if button['parameter'].is_a?(String)
    end
  end

  def process_footer_params(processed_params)
    return if processed_params['footer'].blank?

    processed_params['footer'].each do |key, value|
      processed_params['footer'][key] = process_liquid(value) if value.is_a?(String)
    end
  end

  def process_liquid(value)
    return value if value.blank?

    liquid_service.call(value)
  end

  def liquid_service
    @liquid_service ||= Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact)
  end

  def deep_copy(obj)
    case obj
    when Hash
      obj.transform_values { |v| deep_copy(v) }
    when Array
      obj.map { |v| deep_copy(v) }
    else
      obj.duplicable? ? obj.dup : obj
    end
  end
end
