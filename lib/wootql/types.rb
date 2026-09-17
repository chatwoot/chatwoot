module Wootql::Types
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

  def resolve_comparison(predicate, column)
    operator = predicate.fetch(:operator)
    operand = predicate.fetch(:value)
    return resolve_field_comparison(predicate, column) if operand.is_a?(Hash) && operand.key?(:field)

    values = if operator == 'in' && operand.is_a?(Hash)
               collection = literal(operand)
               raise Wootql::Error, 'Membership parameter must be an array; use in ($value) for a scalar' unless collection.is_a?(Array)

               collection.map { |value| comparison_value(predicate, column, operand, value) }
             else
               expressions = operator == 'in' ? operand : [operand]
               expressions.map { |expression| comparison_value(predicate, column, expression, literal(expression)) }
             end
    operator = 'includes' if column.type == :string_list && operator == 'contains'
    predicate.merge(operator: operator, value: operator == 'in' ? values : values.first)
  end

  def resolve_field_comparison(predicate, column)
    operator = predicate.fetch(:operator)
    raise Wootql::Error, 'Field comparisons support only = != > >= < <=' unless %w[= != > >= < <=].include?(operator)

    other = field(predicate.fetch(:value).fetch(:field))
    unless compatible_types?(column.type, other.type) && (ORDERED_TYPES + [:boolean]).include?(column.type)
      raise Wootql::Error, "Cannot compare #{column.type} and #{other.type} fields"
    end

    if %w[> >= < <=].include?(operator)
      require_ordered!(column)
      require_ordered!(other)
    end
    predicate
  end

  def comparison_value(predicate, column, expression, value)
    check_value!(column, value, predicate.fetch(:operator))
    value
  rescue Wootql::Error => e
    origin = expression.key?(:parameter) ? "Parameter: $#{expression[:parameter]}." : 'Value supplied as a literal or time expression.'
    raise e.with_feedback("Field: #{predicate[:field]}, type: #{column.type}, operator: #{predicate[:operator]}.", origin,
                          "Received value type: #{value.class.name}.",
                          context: ['Use in $values for an array parameter; other parameter positions require scalar values.'])
  end

  def check_value!(definition, value, operator)
    return check_list_value!(value, operator) if definition.type == :string_list

    raise Wootql::Error, 'Use is null or is not null, not a comparison with null' if value.nil?
    raise Wootql::Error, 'contains requires a text field' if operator == 'contains' && %i[string text].exclude?(definition.type)

    raise Wootql::Error, "Expected #{definition.type} value for WootQL comparison" unless valid_value?(definition.type, value)

    check_enum!(definition.enum_values, value)
    require_ordered!(definition) if %w[> >= < <=].include?(operator)
  end

  def check_list_value!(value, operator)
    return if operator == 'contains' && value.is_a?(String)

    raise Wootql::Error, 'List fields require contains with a string value, is [not] empty, or is [not] null'
  end

  def check_enum!(values, value)
    return if values.nil? || values.key?(value)

    raise Wootql::Error, "Expected one of: #{values.keys.join(', ')}"
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

    raise Wootql::Error, "Cannot sort or aggregate a #{definition.type} field"
  end

  def resolve_emptiness(predicate, definition)
    return predicate.merge(type: definition.type) if %i[string text string_list].include?(definition.type)

    raise Wootql::Error, 'is empty / is not empty require a text or list field; use is null for absent values'
  end

  def compatible_types?(left, right)
    return true if left == right
    return true if NUMERIC_TYPES.include?(left) && NUMERIC_TYPES.include?(right)

    %i[string text].include?(left) && %i[string text].include?(right)
  end

  def require_numeric!(definition)
    return if NUMERIC_TYPES.include?(definition.type)

    raise Wootql::Error, 'sum and avg require a numeric field'
  end
end
