# frozen_string_literal: true

# Service to render message templates for bot consumption (Dialogflow, Rasa, etc.)
# Handles parameter validation, variable processing, and channel adaptation
#
# Usage:
#   service = Templates::BotRendererService.new(
#     template_id: 123,
#     parameters: { business_name: 'Acme Corp', available_slots: [...] },
#     channel_type: 'apple_messages_for_business'
#   )
#   result = service.render_for_bot
#
# Returns:
#   {
#     template_id: 123,
#     content_type: 'apple_time_picker',
#     content: 'Select a time',
#     content_attributes: { event: {...}, receivedMessage: {...} },
#     webhook_data: { template_name: '...', parameters_used: {...} }
#   }
class Templates::BotRendererService
  # Custom exception for parameter validation errors
  class ParameterValidationError < StandardError; end

  attr_reader :template, :parameters, :channel_type

  def initialize(template_id:, parameters:, channel_type:)
    @template = MessageTemplate.find(template_id)
    @parameters = if parameters.is_a?(ActionController::Parameters)
                    parameters.to_unsafe_h
                  else
                    parameters
                  end
    @parameters = @parameters.with_indifferent_access
    @channel_type = channel_type
  end

  # Main entry point: render template for bot consumption
  def render_for_bot
    validate_parameters!
    validate_channel_compatibility!

    processed_content = process_template_variables
    channel_content = adapt_for_channel(processed_content)

    {
      template_id: template.id,
      template_name: template.name,
      content_type: channel_content[:content_type],
      content: channel_content[:content],
      content_attributes: channel_content[:content_attributes],
      webhook_data: generate_webhook_data
    }
  end

  private

  # Validate that all required parameters are present and correct type
  def validate_parameters!
    return if template.parameters.blank?

    template.parameters.each do |param_name, config|
      raise ParameterValidationError, "Required parameter '#{param_name}' is missing" if config['required'] && parameters[param_name].blank?

      next if parameters[param_name].blank?

      validate_parameter_type(param_name, parameters[param_name], config['type'])
    end
  end

  # Validate parameter type matches expected type
  def validate_parameter_type(param_name, value, expected_type)
    case expected_type
    when 'string'
      raise ParameterValidationError, "Parameter '#{param_name}' must be a string" unless value.is_a?(String)
    when 'integer'
      raise ParameterValidationError, "Parameter '#{param_name}' must be an integer" unless value.is_a?(Integer) || value.to_i.to_s == value.to_s
    when 'array'
      raise ParameterValidationError, "Parameter '#{param_name}' must be an array" unless value.is_a?(Array)
    when 'boolean'
      raise ParameterValidationError, "Parameter '#{param_name}' must be a boolean" unless [true, false, 'true', 'false'].include?(value)
    when 'datetime'
      begin
        Time.zone.parse(value.to_s)
      rescue ArgumentError
        raise ParameterValidationError, "Parameter '#{param_name}' must be a valid datetime"
      end
    end
  end

  # Validate that the template supports the requested channel
  def validate_channel_compatibility!
    return if template.supported_channels.blank?

    normalized_channel = normalize_channel_type(channel_type)

    return if template.supported_channels.include?(normalized_channel)

    raise ParameterValidationError,
          "Template '#{template.name}' does not support channel '#{channel_type}'. Supported: #{template.supported_channels.join(', ')}"
  end

  # Normalize channel type to standard format
  def normalize_channel_type(channel_type)
    case channel_type.to_s.downcase
    when 'apple_messages_for_business', 'apple_messages', 'amb'
      'apple_messages_for_business'  # Match what's stored in database
    when 'whatsapp', 'whatsapp_business'
      'whatsapp'
    when 'web_widget', 'web', 'website'
      'web_widget'
    else
      channel_type.to_s.downcase
    end
  end

  # Process template content blocks and replace variables with actual values
  def process_template_variables
    content_blocks = template.content_blocks.order(:order_index)

    content_blocks.filter_map do |block|
      # Skip blocks that don't meet conditions
      next unless evaluate_conditions(block.conditions)

      processed_properties = process_block_properties(block.properties)

      {
        type: block.block_type,
        properties: processed_properties,
        conditions: block.conditions
      }
    end
  end

  # Evaluate block conditions (e.g., show only if user_type == 'premium')
  def evaluate_conditions(conditions)
    return true if conditions.blank?

    # Simple condition evaluation: {if: "{{param}} == 'value'"}
    if_condition = conditions['if']
    return true if if_condition.blank?

    # Replace variables in condition
    evaluated_condition = replace_variables_in_string(if_condition)

    # Simple evaluation (can be enhanced with a safe eval library)
    # For now, support basic equality checks
    if evaluated_condition =~ /^['"]?([^'"]+)['"]?\s*==\s*['"]?([^'"]+)['"]?$/
      Regexp.last_match(1).strip == Regexp.last_match(2).strip
    else
      true # Default to true if condition format is not recognized
    end
  end

  # Process properties hash and replace {{variable}} placeholders
  def process_block_properties(properties)
    return {} if properties.blank?

    # Convert to JSON, replace variables, then parse back
    json_string = properties.to_json
    processed_json = replace_variables_in_string(json_string)

    JSON.parse(processed_json)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to process template variables: #{e.message}"
    properties
  end

  # Replace {{variable}} placeholders with actual parameter values
  def replace_variables_in_string(string)
    string.gsub(/\{\{(\w+)\}\}/) do
      param_name = Regexp.last_match(1)
      value = parameters[param_name]

      # Handle different value types
      case value
      when Array, Hash
        value.to_json
      when NilClass
        "{{#{param_name}}}" # Keep placeholder if value not provided
      else
        value.to_s
      end
    end
  end

  # Adapt processed content for specific channel using adapter pattern
  def adapt_for_channel(content_blocks)
    adapter_class = adapter_class_for_channel(channel_type)

    adapter = adapter_class.new(
      content_blocks: content_blocks,
      template: template,
      parameters: parameters
    )

    adapter.adapt
  end

  # Get the appropriate adapter class for the channel
  def adapter_class_for_channel(channel_type)
    case normalize_channel_type(channel_type)
    when 'apple_messages_for_business'
      Templates::Adapters::AppleMessagesTemplateAdapter
    when 'whatsapp'
      Templates::Adapters::WhatsappTemplateAdapter
    when 'web_widget'
      Templates::Adapters::WebWidgetTemplateAdapter
    else
      raise ParameterValidationError, "Unsupported channel type: #{channel_type}"
    end
  end

  # Generate webhook data for external systems to track template usage
  def generate_webhook_data
    {
      template_id: template.id,
      template_name: template.name,
      template_category: template.category,
      parameters_used: parameters.to_h,
      channel_type: channel_type,
      timestamp: Time.current.iso8601
    }
  end
end
