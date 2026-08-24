class Captain::ToolCatalog::Executor
  EVENT_NAME = 'captain.tool_catalog.execute'.freeze

  def initialize(custom_tool:, state: {})
    @custom_tool = custom_tool
    @state = state.to_h
  end

  def perform(params)
    payload = instrumentation_payload
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @response_size = 0

    ActiveSupport::Notifications.instrument(EVENT_NAME, payload) do
      result = execute(params.to_h.deep_stringify_keys)
      payload[:status] = 'success'
      payload[:response_size] = response_size
      result
    rescue Captain::ToolCatalog::ExecutionError => e
      payload.merge!(status: 'error', response_size: response_size, error_category: e.category)
      raise
    rescue StandardError
      payload.merge!(status: 'error', response_size: response_size, error_category: 'upstream')
      raise
    ensure
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      payload[:duration_ms] = (elapsed * 1000).round(2)
    end
  end

  private

  attr_reader :custom_tool, :state, :response_size

  def execute(params)
    validate_tool!
    validate_input!(params)
    step_results = execute_recipe(params)
    Captain::ToolCatalog::SchemaProjector.new(custom_tool.output_schema).project(step_results.last)
  rescue KeyError
    raise Captain::ToolCatalog::ExecutionError.new('validation', 'invalid_tool_snapshot')
  end

  def execute_recipe(params)
    operations = custom_tool.definition.fetch('operations').index_by { |operation| operation.fetch('key') }
    step_results = []

    custom_tool.definition.fetch('recipe').each do |step|
      step_results << execute_step(step, operations, params, step_results)
    end
    step_results
  end

  def execute_step(step, operations, params, step_results)
    arguments = Captain::ToolCatalog::BindingResolver.new(
      model_input: params,
      configuration: custom_tool.configuration,
      state: state,
      step_results: step_results
    ).resolve(step.fetch('bindings'))
    client = client_class.new(
      custom_tool: custom_tool,
      operation: operations.fetch(step.fetch('operation_key'))
    )
    client.perform(arguments)
  ensure
    @response_size += client.response_size if client
  end

  def client_class
    return Captain::ToolCatalog::ShopifyGraphqlClient if custom_tool.provider_key == 'shopify'

    Captain::ToolCatalog::HttpClient
  end

  def validate_tool!
    raise Captain::ToolCatalog::ExecutionError.new('authorization', 'tool_unavailable') unless custom_tool.source_catalog? && custom_tool.enabled?

    Captain::ToolCatalog::RuntimeEligibility.new(custom_tool).ensure!
  end

  def validate_input!(params)
    return if JSONSchemer.schema(custom_tool.input_schema).valid?(params)

    raise Captain::ToolCatalog::ExecutionError.new('validation', 'invalid_tool_input')
  end

  def instrumentation_payload
    {
      provider: custom_tool.provider_key,
      template: custom_tool.template_key,
      status: 'started',
      duration_ms: 0,
      response_size: 0,
      error_category: nil
    }
  end
end
