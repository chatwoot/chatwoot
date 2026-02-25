class Whatsapp::LiquidTemplateProcessorService
  COMPONENT_KEYS = %w[body header buttons footer].freeze

  pattr_initialize [:campaign!, :contact!]

  def process_template_params(template_params)
    return template_params if template_params.blank?

    template_params_copy = template_params.deep_dup
    processed_params = template_params_copy['processed_params']

    return template_params_copy if processed_params.blank?

    case processed_params
    when Array
      process_legacy_array_params(processed_params)
    when Hash
      process_hash_params(processed_params)
    end

    template_params_copy
  end

  private

  def process_hash_params(processed_params)
    if enhanced_component_params?(processed_params)
      process_component_params(processed_params)
    else
      process_legacy_hash_params(processed_params)
    end
  end

  def process_component_params(processed_params)
    process_body_params(processed_params)
    process_header_params(processed_params)
    process_button_params(processed_params)
    process_footer_params(processed_params)
  end

  def process_legacy_hash_params(processed_params)
    processed_params.each do |key, value|
      processed_params[key] = process_liquid(value) if value.is_a?(String)
    end
  end

  def process_legacy_array_params(processed_params)
    processed_params.each_with_index do |value, index|
      processed_params[index] = process_liquid(value) if value.is_a?(String)
    end
  end

  def enhanced_component_params?(processed_params)
    has_component_keys = processed_params.keys.any? { |key| COMPONENT_KEYS.include?(key) }
    return false unless has_component_keys

    valid_component_structure?(processed_params)
  end

  def valid_component_structure?(processed_params)
    valid_body_component?(processed_params['body']) &&
      valid_header_component?(processed_params['header']) &&
      valid_footer_component?(processed_params['footer']) &&
      valid_buttons_component?(processed_params['buttons'])
  end

  def valid_body_component?(body)
    body.nil? || body.is_a?(Hash)
  end

  def valid_header_component?(header)
    header.nil? || header.is_a?(Hash)
  end

  def valid_footer_component?(footer)
    footer.nil? || footer.is_a?(Hash)
  end

  def valid_buttons_component?(buttons)
    buttons.nil? || buttons.is_a?(Array)
  end

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
end
