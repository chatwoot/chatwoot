class Captain::Copilot::Actions::RemoveCustomAttributes < Captain::Copilot::Actions::BaseAction
  NAME = 'remove_custom_attributes'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Remove custom attribute values from each conversation. Arguments: keys, an array of attribute keys.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[keys],
    properties: { keys: { type: 'array', minItems: 1, maxItems: 10, uniqueItems: true, items: { type: 'string', minLength: 1 } } }
  }.deep_stringify_keys.freeze

  # The same write as removing an attribute in the dashboard's attributes panel.
  def perform(record)
    return :skipped unless record.custom_attributes.keys.intersect?(keys)

    record.update!(custom_attributes: record.custom_attributes.except(*keys))
    :applied
  end

  def card(_ids)
    super.merge(values: { attributes: keys.join(', ') })
  end

  private

  def keys
    @arguments['keys']
  end
end
