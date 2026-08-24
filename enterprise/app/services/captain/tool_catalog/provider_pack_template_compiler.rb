class Captain::ToolCatalog::ProviderPackTemplateCompiler
  MAX_TOOL_NAME_LENGTH = 64
  RISK_ORDER = {
    'read' => 0,
    'low_impact_write' => 1,
    'approval_required' => 2
  }.freeze

  def initialize(manifest:, source_loader:, validator:)
    @manifest = manifest
    @source_loader = source_loader
    @validator = validator
    @categories_by_key = manifest.fetch('categories').index_by { |category| category.fetch('key') }
    @operations_by_key = manifest.fetch('operations').index_by { |operation| operation.fetch('key') }
  end

  def compile
    manifest.fetch('templates').map { |template| compile_template(template) }
            .sort_by { |template| template.fetch('key') }
  end

  private

  attr_reader :manifest, :source_loader, :validator, :categories_by_key, :operations_by_key

  def compile_template(template)
    validate_category!(template)
    schemas = load_schemas(template)
    operations = validate_recipe!(template, schemas)
    risk_class = effective_risk(operations)
    validator.validate_template_availability!(template, risk_class)

    template.slice('key', 'version', 'name', 'description', 'category_key', 'availability', 'recipe').merge(
      'stable_name' => stable_name(template),
      'effective_scopes' => effective_scopes(operations),
      'risk_class' => risk_class,
      'model_visible' => model_visible?(template, risk_class),
      'input_schema' => schemas.fetch('input_schema'),
      'configuration_schema' => schemas.fetch('configuration_schema'),
      'output_schema' => schemas.fetch('output_schema')
    )
  end

  def validate_category!(template)
    category_key = template.fetch('category_key')
    return if categories_by_key.key?(category_key)

    raise Captain::ToolCatalog::ProviderPackError,
          "Unknown category for template #{template.fetch('key')}: #{category_key}"
  end

  def load_schemas(template)
    %w[input_schema configuration_schema output_schema].index_with do |key|
      path = template.fetch(key)
      schema = source_loader.load_schema(path)
      validator.reject_secret_literals!(schema, path)
      schema
    end
  end

  def validate_recipe!(template, schemas)
    template.fetch('recipe').each_with_index.map do |step, step_index|
      operation = recipe_operation!(template, step)
      validate_runtime_operation!(operation)
      validate_bindings!(step, step_index, schemas)
      operation
    end
  end

  def recipe_operation!(template, step)
    operation_key = step.fetch('operation_key')
    operation = operations_by_key[operation_key]
    return operation if operation.present?

    raise Captain::ToolCatalog::ProviderPackError,
          "Unknown operation for template #{template.fetch('key')}: #{operation_key}"
  end

  def validate_runtime_operation!(operation)
    return unless operation.fetch('visibility') == 'setup'

    raise Captain::ToolCatalog::ProviderPackError,
          "Setup operation cannot appear in a runtime recipe: #{operation.fetch('key')}"
  end

  def validate_bindings!(step, step_index, schemas)
    step.fetch('bindings').each_value do |binding|
      validator.validate_binding!(
        binding,
        step_index: step_index,
        input_schema: schemas.fetch('input_schema'),
        configuration_schema: schemas.fetch('configuration_schema')
      )
    end
  end

  def stable_name(template)
    name = "#{manifest.fetch('key')}_#{template.fetch('key')}"
    return name if name.length <= MAX_TOOL_NAME_LENGTH

    raise Captain::ToolCatalog::ProviderPackError,
          "Compiled tool name exceeds #{MAX_TOOL_NAME_LENGTH} characters: #{name}"
  end

  def effective_scopes(operations)
    operations.flat_map { |operation| operation.fetch('scopes') }.uniq.sort
  end

  def effective_risk(operations)
    operations.max_by { |operation| RISK_ORDER.fetch(operation.fetch('risk_class')) }.fetch('risk_class')
  end

  def model_visible?(template, risk_class)
    template.fetch('availability') == 'available' && risk_class != 'approval_required'
  end
end
