class Captain::AudienceValidator < ActiveModel::Validator
  GROUP_OPERATORS = %w[and or].freeze
  VALUELESS_OPERATORS = %w[is_present is_not_present].freeze

  def validate(record)
    audience = record.config['audience']
    return if audience.blank?

    record.errors.add(:config, 'audience must be a valid condition tree') unless valid_node?(audience, 1)
  end

  private

  def valid_node?(node, depth)
    return false unless node.is_a?(Hash) && depth <= Captain::AudienceMatcher::MAX_DEPTH

    node = node.with_indifferent_access
    return valid_group?(node, depth) if node.key?(:conditions)

    valid_leaf?(node)
  end

  def valid_group?(node, depth)
    GROUP_OPERATORS.include?(node[:operator].to_s) &&
      node[:conditions].is_a?(Array) &&
      node[:conditions].present? &&
      node[:conditions].all? { |child| valid_node?(child, depth + 1) }
  end

  def valid_leaf?(node)
    return false unless node[:attribute_key].present? && Captain::AudienceMatcher::OPERATORS.include?(node[:filter_operator])
    return true if VALUELESS_OPERATORS.include?(node[:filter_operator])

    node[:values].is_a?(Array) && node[:values].present? && node[:values].all? { |value| value.to_s.present? }
  end
end
