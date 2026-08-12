class Captain::Routines::DslValidator
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

    validate_steps(@dsl['steps'])
  end

  def validate_steps(steps, within_approval: false)
    Array(steps).flat_map do |step|
      next [] unless step.is_a?(Hash)

      errors = validate_step_operation(step, within_approval: within_approval)
      errors.concat(validate_steps(step['do'], within_approval: within_approval || step.key?('approval')))
      errors.concat(validate_steps(step['else'], within_approval: within_approval))
      errors
    end
  end

  def validate_step_operation(step, within_approval:)
    if step['from'].is_a?(Hash)
      validate_collection_query(step['from']['operation'], step['from']['with'])
    elsif step['operation'].present?
      validate_standalone_operation(step, within_approval: within_approval)
    else
      []
    end
  end

  def validate_standalone_operation(step, within_approval:)
    operation = Captain::Routines::Operations::Registry.fetch(step['operation'])
    return ["Operation '#{step['operation']}' is not available"] unless operation

    errors = validate_operation(step['operation'], step['with'], kind: operation.kind)
    errors << "Query operation '#{step['operation']}' requires `save_as`" if operation.kind == 'query' && step['save_as'].blank?
    requires_approval = operation.approval == 'required' && !within_approval
    errors << "Operation '#{step['operation']}' must be nested inside an `approval` step" if requires_approval
    errors
  end

  def validate_collection_query(name, arguments)
    errors = validate_operation(name, arguments, kind: 'query')
    operation = Captain::Routines::Operations::Registry.fetch(name)
    return errors unless operation&.kind == 'query'

    errors << "Query operation '#{name}' must return a collection when used in a for-each `from` block" if operation.return_type != 'collection'
    errors
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
