class Captain::Routines::DslValidator
  TEMPLATE_REFERENCE = /(?:\$\{[^}]+\}|\{\{[^}]+\}\})/
  OUTCOME_ALIAS_FIELDS = %w[action_taken decision_category disposition final_decision final_result].freeze
  RESERVED_RESULT_OUTCOMES = %w[agent_failed].freeze
  RESERVED_RESULT_FIELDS = %w[data outcome reason receipts record_id status].freeze
  SELECTORS = {
    'conversations' => 'conversations.search'
  }.freeze

  def initialize(dsl)
    @dsl = dsl
  end

  def errors
    errors = schema_errors
    errors.empty? ? orchestration_errors : errors
  end

  private

  def schema_errors
    JSONSchemer.schema(Captain::Routines::DslSchema::SCHEMA).validate(@dsl).map do |error|
      path = error['data_pointer'].presence || '/'
      "#{path}: #{error['type']} #{error['details'].to_json}"
    end
  end

  def orchestration_errors
    return [] unless @dsl.is_a?(Hash)

    bindings = {}
    Array(@dsl['steps']).each_with_object([]) do |step, errors|
      next unless step.is_a?(Hash)

      errors.concat(validate_step(step, bindings))
    end
  end

  def validate_step(step, bindings)
    return validate_each(step, bindings) if step['each'].present?
    return validate_reduce(step, bindings) if step['reduce'].present?

    []
  end

  def validate_each(step, bindings)
    validate_template_references(step['from']) +
      validate_selection(step['from']) +
      validate_selection_references(step['from']) +
      validate_result_contract(step.dig('run', 'result')) +
      register_binding(bindings, step['collect_as'], 'collection')
  end

  def validate_result_contract(contract)
    return [] unless contract.is_a?(Hash)

    fields = Array(contract['fields'])
    reserved_result_outcome_errors(contract['outcomes']) +
      duplicate_result_field_errors(fields) +
      fields.flat_map { |field| validate_result_field(field) }
  end

  def reserved_result_outcome_errors(outcomes)
    (Array(outcomes) & RESERVED_RESULT_OUTCOMES).map do |outcome|
      "Result outcome '#{outcome}' is reserved by the Routine runtime"
    end
  end

  def duplicate_result_field_errors(fields)
    names = fields.filter_map { |field| field['name'] if field.is_a?(Hash) }
    names.tally.filter_map do |name, count|
      "Result field '#{name}' is defined more than once" if count > 1
    end
  end

  def validate_result_field(field)
    return [] unless field.is_a?(Hash)

    errors = []
    name = field['name']
    errors << "Result field '#{name}' is reserved by the Routine runtime" if RESERVED_RESULT_FIELDS.include?(name)
    errors << "Result field '#{name}' duplicates the run outcome" if OUTCOME_ALIAS_FIELDS.include?(name)

    values = Array(field['values'])
    if field['type'] == 'enum'
      errors << "Enum result field '#{name}' must define at least one value" if values.empty?
    elsif values.any?
      errors << "Result field '#{name}' may define values only when its type is enum"
    end
    errors
  end

  def validate_reduce(step, bindings)
    validate_reduction(step, bindings) + register_binding(bindings, step['save_as'], 'one')
  end

  def validate_selection(selection)
    return [] unless selection.is_a?(Hash)

    operation_name = SELECTORS[selection['select']]
    return ["Selector '#{selection['select']}' is not available"] unless operation_name

    operation = Captain::Routines::Operations::Registry.fetch(operation_name)
    arguments = selection['where'].is_a?(Hash) ? selection['where'] : {}
    validate_arguments(operation, arguments)
  end

  def validate_reduction(step, bindings)
    reference = step.dig('reduce', 'ref')
    return [] if reference.blank?
    return ["Reduction source '#{reference}' is not defined before this step"] unless bindings.key?(reference)
    return [] if bindings[reference] == 'collection'

    ["Reduction source '#{reference}' must be a collected result"]
  end

  def validate_arguments(operation, arguments)
    return ['Conversation selector operation is not available'] unless operation

    argument_names = arguments.keys
    missing_arguments = operation.required_arguments - argument_names
    unknown_arguments = argument_names - operation.arguments.keys.map(&:to_s)

    missing_arguments.map { |argument| "Conversation selection is missing required filter '#{argument}'" } +
      unknown_arguments.map { |argument| "Conversation selection does not accept filter '#{argument}'" }
  end

  def validate_selection_references(selection)
    references_in(selection).filter_map { |reference| resource_reference_error(reference) }
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

  def resource_reference_error(reference)
    root, resource_name, *path = reference.split('.')
    return "Selection reference '#{reference}' must use a pinned resource" unless root == 'resources'

    resources = @dsl['resources'].is_a?(Hash) ? @dsl['resources'] : {}
    resource = resources[resource_name]
    return "Reference '#{reference}' uses an undefined resource" unless resource

    path.reduce(resource) do |value, segment|
      return "Reference '#{reference}' does not contain '#{segment}'" unless value.is_a?(Hash) && value.key?(segment)

      value[segment]
    end
    nil
  end

  def register_binding(bindings, name, type)
    return [] if name.blank?
    return ["Binding '#{name}' is already defined"] if bindings.key?(name)

    bindings[name] = type
    []
  end

  def validate_template_references(value)
    case value
    when Hash
      value.values.flat_map { |nested| validate_template_references(nested) }
    when Array
      value.flat_map { |nested| validate_template_references(nested) }
    when String
      value.scan(TEMPLATE_REFERENCE).map do |reference|
        "Template reference '#{reference}' is not supported"
      end
    else
      []
    end
  end
end
