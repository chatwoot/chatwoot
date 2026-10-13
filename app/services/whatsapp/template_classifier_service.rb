class Whatsapp::TemplateClassifierService
  SENDABLE = 'sendable'.freeze
  PREVIEW_ONLY = 'preview_only'.freeze
  UNSUPPORTED = 'unsupported'.freeze

  NOT_APPROVED = 'template_not_approved'.freeze
  ADAPTER_UNAVAILABLE = 'parameter_adapter_unavailable'.freeze
  UNSUPPORTED_VERSION = 'unsupported_by_linoo_version'.freeze

  EXCLUDED_CATEGORIES = %w[AUTHENTICATION].freeze
  SUPPORTED_COMPONENTS = %w[HEADER BODY FOOTER BUTTONS].freeze
  SUPPORTED_HEADER_FORMATS = %w[TEXT IMAGE VIDEO DOCUMENT].freeze
  STATIC_BUTTON_TYPES = %w[QUICK_REPLY PHONE_NUMBER].freeze
  PARAMETER_BUTTON_TYPES = %w[URL COPY_CODE].freeze

  attr_reader :template

  def initialize(template)
    @template = template.to_h
  end

  def classified_template
    template.deep_dup.merge(
      'classification' => classification,
      'classification_reason' => classification_reason,
      'required_parameters' => parameter_requirements
    )
  end

  def classification
    return PREVIEW_ONLY unless approved?
    return UNSUPPORTED if excluded_shape?
    return PREVIEW_ONLY unless adapter_supported?

    SENDABLE
  end

  def classification_reason
    case classification
    when SENDABLE then nil
    when UNSUPPORTED then UNSUPPORTED_VERSION
    else approved? ? ADAPTER_UNAVAILABLE : NOT_APPROVED
    end
  end

  def sendable?
    classification == SENDABLE
  end

  def parameter_requirements
    return [] unless adapter_supported?

    components.flat_map.with_index do |component, component_index|
      requirements_for(component, component_index)
    end
  end

  private

  def approved?
    template['status'].to_s.casecmp('approved').zero?
  end

  def components
    Array(template['components'])
  end

  def excluded_shape?
    return true if EXCLUDED_CATEGORIES.include?(template['category'].to_s.upcase)
    return true if components.empty?
    return true if components.any? { |component| unsupported_component?(component) }

    components.any? { |component| unsupported_component_contents?(component) }
  end

  def unsupported_component?(component)
    SUPPORTED_COMPONENTS.exclude?(component['type'].to_s.upcase)
  end

  def unsupported_component_contents?(component)
    case component['type'].to_s.upcase
    when 'HEADER' then unsupported_header?(component)
    when 'BUTTONS' then unsupported_buttons?(component)
    else false
    end
  end

  def unsupported_header?(component)
    SUPPORTED_HEADER_FORMATS.exclude?(component['format'].to_s.upcase)
  end

  def unsupported_buttons?(component)
    supported_types = STATIC_BUTTON_TYPES + PARAMETER_BUTTON_TYPES
    Array(component['buttons']).any? { |button| supported_types.exclude?(button['type'].to_s.upcase) }
  end

  def adapter_supported?
    return false if excluded_shape?

    components.all? do |component|
      type = component['type'].to_s.upcase
      next false if type == 'FOOTER' && variables(component['text']).any?
      next false if type == 'BUTTONS' && unsupported_button_parameters?(component)

      true
    end
  end

  def unsupported_button_parameters?(component)
    Array(component['buttons']).any? do |button|
      button_type = button['type'].to_s.upcase
      button_type == 'URL' && variables(button['url']).length > 1
    end
  end

  def requirements_for(component, component_index)
    case component['type'].to_s.upcase
    when 'HEADER' then header_requirements(component, component_index)
    when 'BODY' then text_requirements(component, component_index, 'body')
    when 'BUTTONS' then button_requirements(component, component_index)
    else []
    end
  end

  def header_requirements(component, component_index)
    format = component['format'].to_s.upcase
    return text_requirements(component, component_index, 'header') if format == 'TEXT'

    [{
      'component' => 'header',
      'component_index' => component_index,
      'kind' => 'media',
      'format' => format.downcase
    }]
  end

  def text_requirements(component, component_index, component_name)
    variables(component['text']).map.with_index do |key, index|
      {
        'component' => component_name,
        'component_index' => component_index,
        'kind' => 'text',
        'key' => key,
        'position' => index
      }
    end
  end

  def button_requirements(component, component_index)
    Array(component['buttons']).filter_map.with_index do |button, button_index|
      type = button['type'].to_s.upcase
      next unless PARAMETER_BUTTON_TYPES.include?(type)
      next if type == 'URL' && variables(button['url']).empty?

      {
        'component' => 'buttons',
        'component_index' => component_index,
        'kind' => type.downcase,
        'button_index' => button_index,
        'url' => button['url'],
        'variables' => variables(button['url'])
      }.compact
    end
  end

  def variables(text)
    text.to_s.scan(/{{([^{}]+)}}/).flatten.uniq
  end
end
