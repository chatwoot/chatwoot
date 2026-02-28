class Captain::Workflows::Nodes::ConditionNode < Captain::Workflows::Nodes::BaseNode
  def execute
    result = evaluate_condition
    { next_handle: result ? 'true' : 'false' }
  end

  private

  def evaluate_condition
    attribute = node_data['attribute']
    operator = node_data['operator']
    value = node_data['value']

    actual_value = resolve_attribute(attribute)
    compare(actual_value, operator, value)
  end

  def resolve_attribute(attribute)
    case attribute
    when /\Aconversation\./
      conversation&.send(attribute.sub('conversation.', ''))
    when /\Acontact\./
      contact&.send(attribute.sub('contact.', ''))
    else
      context.dig(*attribute.split('.').map(&:to_sym))
    end
  rescue NoMethodError
    nil
  end

  def compare(actual, operator, expected)
    case operator
    when 'equals' then actual.to_s == expected.to_s
    when 'not_equals' then actual.to_s != expected.to_s
    when 'contains' then actual.to_s.include?(expected.to_s)
    when 'not_contains' then actual.to_s.exclude?(expected.to_s)
    when 'is_present' then actual.present?
    when 'is_blank' then actual.blank?
    else false
    end
  end
end
