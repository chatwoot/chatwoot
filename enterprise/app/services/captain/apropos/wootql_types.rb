module Captain::Apropos::WootqlTypes
  NUMERIC_TYPES = %i[integer float decimal].freeze
  ORDERED_TYPES = %i[integer float decimal string text datetime date].freeze
  VALUE_CHECKS = {
    integer: ->(value) { value.is_a?(Integer) && value.between?(-(2**63), (2**63) - 1) },
    float: ->(value) { value.is_a?(Numeric) && value.finite? },
    decimal: ->(value) { value.is_a?(Numeric) && value.finite? },
    string: ->(value) { value.is_a?(String) },
    text: ->(value) { value.is_a?(String) },
    boolean: ->(value) { [true, false].include?(value) }
  }.freeze

  private

  def check_value!(definition, value, operator)
    return check_list_value!(value, operator) if definition.type == :string_list

    raise Captain::Apropos::Error, 'Use is null or is not null, not a comparison with null' if value.nil?
    raise Captain::Apropos::Error, 'contains requires a text field' if operator == 'contains' && %i[string text].exclude?(definition.type)

    raise Captain::Apropos::Error, "Expected #{definition.type} value for WootQL comparison" unless valid_value?(definition.type, value)

    check_enum!(definition.enum_values, value)
    require_ordered!(definition) if %w[> >= < <=].include?(operator)
  end

  def check_list_value!(value, operator)
    return if operator == 'contains' && value.is_a?(String)

    raise Captain::Apropos::Error, 'List fields require contains with a string value'
  end

  def check_enum!(values, value)
    return if values.nil? || values.key?(value)

    raise Captain::Apropos::Error, "Expected one of: #{values.keys.join(', ')}"
  end

  def valid_value?(type, value)
    return time_value?(value) if %i[datetime date].include?(type)

    VALUE_CHECKS.key?(type) && VALUE_CHECKS.fetch(type).call(value)
  end

  def time_value?(value)
    return true if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

    value.is_a?(String) && Time.iso8601(value)
  rescue ArgumentError
    false
  end

  def require_ordered!(definition)
    return if ORDERED_TYPES.include?(definition.type)

    raise Captain::Apropos::Error, "Cannot sort or aggregate a #{definition.type} field"
  end

  def compatible_types?(left, right)
    left == right || (NUMERIC_TYPES.include?(left) && NUMERIC_TYPES.include?(right))
  end

  def require_numeric!(definition)
    return if NUMERIC_TYPES.include?(definition.type)

    raise Captain::Apropos::Error, 'sum and avg require a numeric field'
  end
end
