class Captain::Tool
  class InvalidImplementationError < StandardError; end
  class InvalidSecretsError < StandardError; end
  class ExecutionError < StandardError; end

  MANDATORY_FIELDS = %w[name description properties secrets].freeze

  attr_reader :name, :description, :properties, :secrets, :implementation, :memory

  def initialize(name:, config:)
    @name = name
    @description = config[:description]
    @properties = config[:properties]
    @secrets = config[:secrets] || []
    @implementation = config[:implementation]
    @memory = config[:memory] || {}
  end

  def execute(input_data, available_secrets = {})
    ensure_secrets_present!(available_secrets)
    ensure_input_valid!(input_data)

    raise ExecutionError, 'Implementation block is missing' unless @implementation

    instance_exec(input_data, available_secrets, memory, &@implementation)
  rescue StandardError => e
    raise ExecutionError, "Tool execution failed: #{e.message}"
  end

  def register_method(&block)
    @implementation = block
  end

  private

  def ensure_secrets_present!(available_secrets)
    required = secrets.map(&:to_sym)
    missing = required - available_secrets.keys

    raise InvalidSecretsError, "Missing required secrets: #{missing.join(', ')}" if missing.any?
  end

  def ensure_input_valid!(input_data)
    properties.each do |field, rules|
      val = input_data[field.to_sym]
      raise ArgumentError, "Missing required property: #{field}" if rules['required'] && val.nil?
    end
  end
end
