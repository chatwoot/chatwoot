class Captain::Tool
  class InvalidImplementationError < StandardError; end
  class InvalidSecretsError < StandardError; end
  class ExecutionError < StandardError; end

  REQUIRED_PROPERTIES = %w[name description properties secrets].freeze

  attr_reader :name, :description, :properties, :secrets, :implementation, :memory

  def initialize(name:, config:)
    @name = name
    @description = config[:description]
    @properties =  config[:properties]
    @secrets =  config[:secrets] || []
    @implementation = config[:implementation]
    @memory = config[:memory] || {}
  end

  def register_method(&block)
    @implementation = block
  end

  def execute(input, provided_secrets = {})
    validate_secrets!(provided_secrets)
    validate_input!(input)

    raise ExecutionError, 'No implementation registered' unless @implementation

    instance_exec(input, provided_secrets, memory, &@implementation)
  rescue StandardError => e
    raise ExecutionError, "Execution failed: #{e.message}"
  end

  private

  def validate_config!(config)
    missing_keys = REQUIRED_PROPERTIES - config.keys
    return if missing_keys.empty?

    raise InvalidImplementationError,
          "Missing required properties: #{missing_keys.join(', ')}"
  end

  def validate_secrets!(provided_secrets)
    required_secrets = secrets.map!(&:to_sym)
    missing_secrets = required_secrets - provided_secrets.keys

    return if missing_secrets.empty?

    raise InvalidSecretsError, "Missing required secrets: #{missing_secrets.join(', ')}"
  end

  def validate_input!(input)
    properties.each do |property, constraints|
      validate_property!(input, property, constraints)
    end
  end

  def validate_property!(input, property, constraints)
    value = input[property.to_sym]

    raise ArgumentError, "Missing required property: #{property}" if constraints['required'] && value.nil?

    true
  end
end
