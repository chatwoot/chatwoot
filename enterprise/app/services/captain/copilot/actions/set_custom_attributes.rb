class Captain::Copilot::Actions::SetCustomAttributes < Captain::Copilot::Actions::BaseAction
  NAME = 'set_custom_attributes'.freeze
  RESOURCE = 'conversations'.freeze
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze
  DESCRIPTION = 'Set custom attributes on each conversation. Arguments: attributes, an object from attribute keys defined in the ' \
                'account to their values.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[attributes],
    properties: { attributes: { type: 'object', minProperties: 1, maxProperties: 10, additionalProperties: { type: %w[string number boolean] } } }
  }.deep_stringify_keys.freeze

  # The same write as the dashboard's attributes panel, which keeps the other attributes.
  def perform(record)
    merged = record.custom_attributes.merge(attributes)
    return :skipped if merged == record.custom_attributes

    record.update!(custom_attributes: merged)
    :applied
  end

  def card(_ids)
    super.merge(values: { attributes: attributes.map { |key, value| "#{key}: #{value}" }.join(', ') })
  end

  private

  def attributes
    @arguments['attributes']
  end

  def validate!
    definitions = @account.custom_attribute_definitions.where(attribute_model: self.class::ATTRIBUTE_MODEL)
    unknown = attributes.keys - definitions.where(attribute_key: attributes.keys).pluck(:attribute_key)
    return if unknown.empty?

    raise ArgumentError, "Unknown attributes: #{unknown.join(', ')}. " \
                         "Available attributes: #{definitions.order(:attribute_key).limit(100).pluck(:attribute_key).join(', ')}"
  end
end
