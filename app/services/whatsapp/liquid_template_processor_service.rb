class Whatsapp::LiquidTemplateProcessorService
  COMPONENT_KEYS = %w[body header buttons footer].freeze

  pattr_initialize [:campaign!, :contact!]

  def process_template_params(template_params)
    return template_params if template_params.blank?

    template_params_copy = template_params.deep_dup
    processed_params = template_params_copy['processed_params']

    return template_params_copy if processed_params.blank?

    @has_blank_values = false

    case processed_params
    when Array
      process_legacy_array_params(processed_params)
    when Hash
      process_hash_params(processed_params)
    end

    return nil if @has_blank_values

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
    %w[body header footer].each { |key| process_hash_component(processed_params, key) }
    process_button_params(processed_params)
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
    %w[body header footer].all? { |key| processed_params[key].nil? || processed_params[key].is_a?(Hash) } &&
      (processed_params['buttons'].nil? || processed_params['buttons'].is_a?(Array))
  end

  def process_hash_component(processed_params, key)
    return if processed_params[key].blank?

    processed_params[key].each do |k, value|
      processed_params[key][k] = process_liquid(value) if value.is_a?(String)
    end
  end

  def process_button_params(processed_params)
    return if processed_params['buttons'].blank?

    processed_params['buttons'].each do |button|
      next if button.blank?

      button['parameter'] = process_liquid(button['parameter']) if button['parameter'].is_a?(String)
    end
  end

  def process_liquid(value)
    return value if value.blank?

    rendered = liquid_service.call(value)
    @has_blank_values = true if rendered.blank? && value.present?
    rendered
  end

  def liquid_service
    @liquid_service ||= Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact)
  end
end
