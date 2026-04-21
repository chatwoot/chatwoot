# Service to convert legacy WhatsApp template parameter formats to enhanced format
#
# Legacy formats (deprecated):
# - Array: ["John", "Order123"] - positional parameters
# - Flat Hash: {"1": "John", "2": "Order123"} - direct key-value mapping
#
# Enhanced format:
# - Component-based: {"body": {"1": "John", "2": "Order123"}} - structured by template components
# - Supports header, body, footer, and button parameters separately
#
class Whatsapp::TemplateParameterConverterService
  def initialize(template_params, template)
    @template_params = template_params
    @template = template
  end

  def normalize_to_enhanced
    processed_params = @template_params['processed_params']

    # Early return if already enhanced format
    return @template_params if enhanced_format?(processed_params)

    # Mark as legacy format before conversion for tracking
    @template_params['format_version'] = 'legacy'

    # Convert legacy formats to enhanced structure
    # TODO: Legacy format support will be deprecated and removed after 2-3 releases
    enhanced_params = convert_legacy_to_enhanced(processed_params, @template)

    # Replace original params with enhanced structure
    @template_params['processed_params'] = enhanced_params

    @template_params
  end

  private

  def enhanced_format?(processed_params)
    return false unless processed_params.is_a?(Hash)

    # Enhanced format has component-based structure
    component_keys = %w[body header footer buttons]
    has_component_structure = processed_params.keys.any? { |k| component_keys.include?(k) }

    # Additional validation for enhanced format
    if has_component_structure
      validate_enhanced_structure(processed_params)
    else
      false
    end
  end

  def validate_enhanced_structure(params)
    valid_body?(params['body']) &&
      valid_header?(params['header']) &&
      valid_buttons?(params['buttons'])
  end

  def valid_body?(body)
    body.nil? || body.is_a?(Hash)
  end

  def valid_header?(header)
    header.nil? || header.is_a?(Hash)
  end

  def valid_buttons?(buttons)
    return true if buttons.nil?
    return false unless buttons.is_a?(Array)

    buttons.all? { |b| b.is_a?(Hash) && b['type'] }
  end

  def convert_legacy_to_enhanced(legacy_params, _template)
    # Legacy system only supported text-based templates with body parameters
    # We only convert the parameter format, not add new features

    enhanced = {}

    case legacy_params
    when Array
      # Array format: ["John", "Order123"] → {body: {"1": "John", "2": "Order123"}}
      body_params = convert_array_to_body_params(legacy_params)
      enhanced['body'] = body_params unless body_params.empty?
    when Hash
      # Hash format: {"1": "John", "name": "Jane"} → {body: {"1": "John", "name": "Jane"}}
      body_params = convert_hash_to_body_params(legacy_params)
      enhanced['body'] = body_params unless body_params.empty?
    when NilClass
      # Templates without parameters (nil processed_params)
      # Return empty enhanced structure
    else
      raise ArgumentError, "Unknown legacy format: #{legacy_params.class}"
    end

    enhanced
  end

  def convert_array_to_body_params(params_array)
    return {} if params_array.empty?

    body_params = {}
    params_array.each_with_index do |value, index|
      body_params[(index + 1).to_s] = value.to_s
    end

    body_params
  end

  def convert_hash_to_body_params(params_hash)
    return {} if params_hash.empty?

    body_params = {}
    params_hash.each do |key, value|
      body_params[key.to_s] = value.to_s
    end

    body_params
  end
end
