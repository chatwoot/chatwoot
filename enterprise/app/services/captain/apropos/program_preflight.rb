# Inspect literal result schemas without evaluating code or calling tools.
class Captain::Apropos::ProgramPreflight
  UNKNOWN = Object.new.freeze
  SCHEMA_ARGUMENTS = { reason: 3, 'spawn-agent': 3, 'schema-check': 1 }.freeze

  def initialize(scheme)
    @shadowed = scheme.workspace.keys | scheme.library.keys
  end

  def check(expressions)
    @shadowed |= expressions.flat_map { |expression| bindings(expression) }
    expressions.each { |expression| walk(expression) }
  end

  private

  def bindings(expression)
    return [] unless expression.is_a?(Array) && expression.first != :quote

    names = case expression.first
            when :define, :lambda then Array(expression[1]).grep(Symbol)
            when :let, :'let*', :letrec then let_bindings(expression)
            else []
            end
    names + expression.flat_map { |item| bindings(item) }
  end

  def let_bindings(expression)
    named = expression[1].is_a?(Symbol)
    pairs = expression[named ? 2 : 1]
    return [] unless pairs.is_a?(Array)

    names = pairs.filter_map { |pair| pair.first if pair.is_a?(Array) && pair.first.is_a?(Symbol) }
    named ? names + [expression[1]] : names
  end

  def walk(expression)
    return unless expression.is_a?(Array) && expression.first != :quote

    check_schema(expression)
    expression.each { |item| walk(item) }
  end

  def check_schema(expression)
    index = SCHEMA_ARGUMENTS[expression.first]
    return unless index && @shadowed.exclude?(expression.first)

    value = literal(expression[index])
    Captain::Apropos::ResultSchema.build(value) unless value.equal?(UNKNOWN)
  rescue Captain::Apropos::Error => e
    raise Captain::Apropos::Error, "Schema preflight failed before execution: #{e.message}"
  end

  def literal(expression)
    case expression
    when Symbol then UNKNOWN
    when Array then literal_list(expression)
    else expression
    end
  end

  def literal_list(expression)
    return expression.fetch(1, UNKNOWN) if expression.first == :quote
    return UNKNOWN unless %i[hash list].include?(expression.first) && @shadowed.exclude?(expression.first)

    values = expression.drop(1).map { |item| literal(item) }
    return UNKNOWN if values.include?(UNKNOWN)

    expression.first == :hash ? Captain::Apropos::CoreFunctions.build_hash(values) : values
  end
end
