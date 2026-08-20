class Captain::AudienceValidator < ActiveModel::Validator
  GROUP_OPERATORS = %w[and or].freeze
  VALUELESS_OPERATORS = %w[is_present is_not_present].freeze
  EQUALITY_OPERATORS = %w[equal_to not_equal_to].freeze
  CONTAINMENT_OPERATORS = %w[equal_to not_equal_to contains does_not_contain].freeze
  DATE_OPERATORS = %w[is_greater_than is_less_than days_before].freeze
  COMPARISON_OPERATORS = %w[equal_to not_equal_to is_present is_not_present is_greater_than is_less_than].freeze

  STANDARD_ATTRIBUTE_OPERATORS = {
    'name' => EQUALITY_OPERATORS,
    'email' => CONTAINMENT_OPERATORS,
    'phone_number' => CONTAINMENT_OPERATORS,
    'identifier' => EQUALITY_OPERATORS,
    'blocked' => EQUALITY_OPERATORS,
    'created_at' => DATE_OPERATORS,
    'last_activity_at' => DATE_OPERATORS,
    'country_code' => EQUALITY_OPERATORS,
    'city' => CONTAINMENT_OPERATORS,
    'company_name' => CONTAINMENT_OPERATORS,
    'labels' => EQUALITY_OPERATORS,
    'hmac_verified' => EQUALITY_OPERATORS,
    'browser_language' => EQUALITY_OPERATORS
  }.freeze

  CUSTOM_ATTRIBUTE_OPERATORS = {
    'text' => CONTAINMENT_OPERATORS,
    'number' => EQUALITY_OPERATORS,
    'currency' => EQUALITY_OPERATORS,
    'percent' => EQUALITY_OPERATORS,
    'link' => EQUALITY_OPERATORS,
    'date' => COMPARISON_OPERATORS,
    'list' => EQUALITY_OPERATORS,
    'checkbox' => EQUALITY_OPERATORS
  }.freeze

  def validate(record)
    audience = record.config['audience']
    return if audience.blank?

    custom_attribute_types = record.account.custom_attribute_definitions.contact_attribute.each_with_object({}) do |definition, types|
      types[definition.attribute_key] = definition.attribute_display_type
    end

    record.errors.add(:config, 'audience must be a valid condition tree') unless valid_node?(audience, 1, custom_attribute_types)
  end

  private

  def valid_node?(node, depth, custom_attribute_types)
    return false unless node.is_a?(Hash) && depth <= Captain::AudienceMatcher::MAX_DEPTH

    node = node.with_indifferent_access
    return valid_group?(node, depth, custom_attribute_types) if node.key?(:conditions)

    valid_leaf?(node, custom_attribute_types)
  end

  def valid_group?(node, depth, custom_attribute_types)
    GROUP_OPERATORS.include?(node[:operator].to_s) &&
      node[:conditions].is_a?(Array) &&
      node[:conditions].present? &&
      node[:conditions].all? { |child| valid_node?(child, depth + 1, custom_attribute_types) }
  end

  def valid_leaf?(node, custom_attribute_types)
    operator = node[:filter_operator].to_s
    allowed_operators = allowed_operators(node[:attribute_key].to_s, custom_attribute_types)
    return false unless allowed_operators&.include?(operator)
    return true if VALUELESS_OPERATORS.include?(operator)

    node[:values].is_a?(Array) && node[:values].present? && node[:values].all? { |value| value.to_s.present? }
  end

  def allowed_operators(attribute_key, custom_attribute_types)
    STANDARD_ATTRIBUTE_OPERATORS[attribute_key] || CUSTOM_ATTRIBUTE_OPERATORS[custom_attribute_types[attribute_key]]
  end
end
