class Captain::Routines::DslValidator
  TEMPLATE_REFERENCE = /(?:\$\{[^}]+\}|\{\{[^}]+\}\})/

  def initialize(dsl)
    @dsl = dsl
  end

  def errors
    schema_errors + operation_errors
  end

  private

  def schema_errors
    JSONSchemer.schema(Captain::Routines::DslSchema::SCHEMA).validate(@dsl).map do |error|
      path = error['data_pointer'].presence || '/'
      "#{path}: #{error['type']} #{error['details'].to_json}"
    end
  end

  def operation_errors
    return [] unless @dsl.is_a?(Hash)

    validate_steps(@dsl['steps'], {})
  end

  def validate_steps(steps, bindings)
    Array(steps).each_with_object([]) do |step, errors|
      next unless step.is_a?(Hash)

      errors.concat(validate_step_operation(step, bindings))
      errors.concat(validate_step_references(step, bindings))
      errors.concat(validate_nested_steps(step, bindings))
      register_step_result(step, bindings)
    end
  end

  def validate_step_operation(step, bindings)
    if step['from'].is_a?(Hash)
      validate_loop_source(step['from'], bindings)
    elsif step['operation'].present?
      validate_standalone_operation(step)
    else
      []
    end
  end

  def validate_nested_steps(step, bindings)
    nested_bindings = bindings.dup
    nested_bindings[step['each']] = 'one' if step['each'].present?

    errors = validate_steps(step['do'], nested_bindings)
    errors.concat(validate_steps(step['else'], bindings.dup))
  end

  def register_step_result(step, bindings)
    operation = Captain::Routines::Operations::Registry.fetch(step['operation'])
    bindings[step['save_as']] = operation.return_type if operation&.kind == 'query' && step['save_as'].present?
    bindings[step['decide']] = 'one' if step['decide'].present?
    bindings[step['compose']] = 'rich_message' if step['compose'].present?
  end

  def validate_standalone_operation(step)
    operation = Captain::Routines::Operations::Registry.fetch(step['operation'])
    return ["Operation '#{step['operation']}' is not available"] unless operation

    errors = validate_operation(step['operation'], step['with'], kind: operation.kind)
    errors << "Query operation '#{step['operation']}' requires `save_as`" if operation.kind == 'query' && step['save_as'].blank?
    errors
  end

  def validate_collection_query(name, arguments)
    errors = validate_operation(name, arguments, kind: 'query')
    operation = Captain::Routines::Operations::Registry.fetch(name)
    return errors unless operation&.kind == 'query'

    errors << "Query operation '#{name}' must return a collection when used in a for-each `from` block" if operation.return_type != 'collection'
    errors
  end

  def validate_loop_source(source, bindings)
    return validate_collection_reference(source['ref'], bindings) if source['ref'].present?

    validate_collection_query(source['operation'], source['with'])
  end

  def validate_collection_reference(name, bindings)
    return ["Loop source '#{name}' is not defined"] unless bindings.key?(name)
    return [] if bindings[name] == 'collection'

    ["Loop source '#{name}' must reference a collection query result"]
  end

  def validate_step_references(step, bindings)
    values = step.values_at('with', 'about', 'when', 'context', 'mention_bindings')
    syntax_errors = values.flat_map { |value| template_reference_errors_in(value) }
    references = values.flat_map { |value| references_in(value) }.uniq
    binding_errors = references.filter_map do |reference|
      root = reference.split('.').first
      "Reference '#{reference}' is not defined before this step" unless bindings.key?(root)
    end
    syntax_errors + binding_errors + required_mention_errors(step)
  end

  def required_mention_errors(step)
    required_mentions = Array(step['required_mentions'])
    return [] if required_mentions.empty?

    available_mentions = step['mention_bindings'].is_a?(Hash) ? step['mention_bindings'].keys : []
    (required_mentions - available_mentions).map do |mention|
      "Required mention '#{mention}' is not declared in `mention_bindings`"
    end
  end

  def references_in(value)
    case value
    when Hash
      direct_reference = value['ref'].is_a?(String) ? [value['ref']] : []
      direct_reference + value.except('ref').values.flat_map { |nested| references_in(nested) }
    when Array
      value.flat_map { |nested| references_in(nested) }
    else
      []
    end
  end

  def template_reference_errors_in(value)
    case value
    when Hash
      value.values.flat_map { |nested| template_reference_errors_in(nested) }
    when Array
      value.flat_map { |nested| template_reference_errors_in(nested) }
    when String
      value.scan(TEMPLATE_REFERENCE).map do |reference|
        "Template reference '#{reference}' is not supported; use a `{ \"ref\": \"binding.path\" }` object"
      end
    else
      []
    end
  end

  def validate_operation(name, arguments, kind:)
    registry = Captain::Routines::Operations::Registry
    return ["Operation '#{name}' is not an available #{kind}"] unless registry.include?(name, kind: kind)

    operation = registry.fetch(name)
    argument_names = arguments.is_a?(Hash) ? arguments.keys : []
    missing_arguments = operation.required_arguments - argument_names
    unknown_arguments = argument_names - operation.arguments.keys.map(&:to_s)

    missing_arguments.map { |argument| "Operation '#{name}' is missing required argument '#{argument}'" } +
      unknown_arguments.map { |argument| "Operation '#{name}' does not accept argument '#{argument}'" }
  end
end
