class Whatsapp::TemplateParameterValidationService
  class ValidationError < StandardError; end

  CURRENCY_KEYS = %w[type fallback_value code amount_1000].freeze
  DATE_TIME_KEYS = %w[type fallback_value day_of_week day_of_month month year].freeze
  URL_BUTTON_KEYS = %w[type parameter url variables index].freeze

  pattr_initialize [:template!, :requirements!, :processed_params!]

  def call
    validate_component_format!
    validate_extra_sections!
    validate_text_parameters!('header')
    validate_media_header!
    validate_text_parameters!('body')
    validate_button_parameters!
  end

  private

  def validate_component_format!
    raise ValidationError, 'Template parameters must use the component format' unless processed_params.is_a?(Hash)
  end

  def validate_extra_sections!
    expected = requirements.pluck('component').uniq
    supplied = processed_params.select { |_key, value| value.present? }.keys
    extra = supplied - expected
    raise ValidationError, "Unexpected template parameters: #{extra.join(', ')}" if extra.any?
  end

  def validate_text_parameters!(component)
    expected = requirements.select { |item| text_requirement?(item, component) }.pluck('key')
    return if expected.empty?

    values = processed_params[component]
    raise ValidationError, "Missing #{component} template parameters" unless values.is_a?(Hash)
    unless matching_keys?(values, expected)
      raise ValidationError, "#{component.capitalize} template parameters do not match the synchronized template"
    end

    values.each { |key, value| validate_parameter_value!(value, "#{component}.#{key}") }
  end

  def text_requirement?(item, component)
    item['component'] == component && item['kind'] == 'text'
  end

  def matching_keys?(values, expected)
    values.keys.map(&:to_s).sort == expected.sort
  end

  def validate_parameter_value!(value, label)
    raise ValidationError, "Template parameter #{label} cannot be blank" if value.blank?
    return unless value.is_a?(Hash)
    raise ValidationError, "Template parameter #{label} must be text" if template['parameter_format'] == 'NAMED'

    validate_structured_parameter!(value, label)
  end

  def validate_structured_parameter!(value, label)
    case value['type']
    when 'currency' then validate_currency!(value, label)
    when 'date_time' then validate_date_time!(value, label)
    else raise ValidationError, "Template parameter #{label} has an unsupported structured value"
    end
  end

  def validate_currency!(value, label)
    raise ValidationError, "Template parameter #{label} has invalid currency fields" unless value.keys.sort == CURRENCY_KEYS.sort
    raise ValidationError, "Template parameter #{label} has blank currency fields" if CURRENCY_KEYS.drop(1).any? { |key| value[key].blank? }
  end

  def validate_date_time!(value, label)
    raise ValidationError, "Template parameter #{label} has invalid date-time fields" if (value.keys - DATE_TIME_KEYS).any?
    raise ValidationError, "Template parameter #{label} needs a date-time fallback" if value['fallback_value'].blank?
  end

  def validate_media_header!
    requirement = requirements.find { |item| media_requirement?(item) }
    return unless requirement

    header = processed_params['header']
    raise ValidationError, 'Missing header template parameters' unless header.is_a?(Hash)

    validate_media_header_fields!(header, requirement)
  end

  def media_requirement?(item)
    item['component'] == 'header' && item['kind'] == 'media'
  end

  def validate_media_header_fields!(header, requirement)
    allowed = %w[media_url media_type]
    allowed << 'media_name' if requirement['format'] == 'document'
    raise ValidationError, 'Header template parameters do not match the synchronized template' if (header.keys - allowed).any?
    raise ValidationError, 'Header media URL cannot be blank' if header['media_url'].blank?
    raise ValidationError, 'Header media type does not match the synchronized template' unless header['media_type'] == requirement['format']
  end

  def validate_button_parameters!
    expected = requirements.select { |item| item['component'] == 'buttons' }
    return if expected.empty?

    buttons = processed_params['buttons']
    raise ValidationError, 'Button template parameters do not match the synchronized template' unless buttons.is_a?(Array)

    button_pairs(buttons, expected).each { |button, requirement| validate_button_parameter!(button, requirement) }
  end

  def button_pairs(buttons, expected)
    return buttons.zip(expected) if buttons.length == expected.length

    expected_indexes = expected.pluck('button_index')
    supplied_indexes = buttons.each_index.select { |index| buttons[index].present? }
    unless supplied_indexes == expected_indexes && buttons.length == expected_indexes.max + 1
      raise ValidationError, 'Button template parameters do not match the synchronized template'
    end

    expected.map { |requirement| [buttons[requirement['button_index']], requirement] }
  end

  def validate_button_parameter!(button, requirement)
    raise ValidationError, 'Button template parameter is invalid' unless button.is_a?(Hash)
    raise ValidationError, 'Button type does not match the synchronized template' unless button['type'] == requirement['kind']
    raise ValidationError, 'Button template parameter cannot be blank' if button['parameter'].blank?

    requirement['kind'] == 'url' ? validate_url_button!(button, requirement) : validate_copy_code_button!(button)
  end

  def validate_copy_code_button!(button)
    raise ValidationError, 'Copy-code button contains unexpected fields' if (button.keys - %w[type parameter]).any?
  end

  def validate_url_button!(button, requirement)
    raise ValidationError, 'URL button contains unexpected fields' if (button.keys - URL_BUTTON_KEYS).any?
    raise ValidationError, 'URL button definition does not match the synchronized template' unless button['url'] == requirement['url']
    raise ValidationError, 'URL button variables do not match the synchronized template' unless Array(button['variables']) == requirement['variables']
    return if button['index'].nil? || button['index'].to_s == requirement['button_index'].to_s

    raise ValidationError, 'URL button index does not match the synchronized template'
  end
end
