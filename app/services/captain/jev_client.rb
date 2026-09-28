class Captain::JevClient
  include Integrations::LlmInstrumentationConstants

  ENDPOINT = 'https://openrouter.ai/api'.freeze
  SYSTEM_ONE_PATH = '/v1/systemone'.freeze

  class HTTPError < StandardError
    attr_reader :status, :retry_after

    def initialize(response)
      @status = response.status
      @retry_after = response.headers['retry-after']&.to_i
      super("Jev request failed with status #{status}: #{response.body}")
    end
  end

  def initialize(account_id:, feature:, conversation_id: nil)
    @account_id = account_id
    @conversation_id = conversation_id
    @feature = feature
  end

  def self.request_body(model:, state:, questions:)
    { model: model, state: state, questions: questions }.to_json
  end

  def self.api_key
    GlobalConfigService.load('CAPTAIN_OPENROUTER_API_KEY', nil)
  end

  def self.endpoint
    base_url = GlobalConfigService.load('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).presence || ENDPOINT
    "#{base_url.chomp('/')}#{SYSTEM_ONE_PATH}"
  end

  def call(body:)
    trace_jev_call(body) do
      response = connection.post(self.class.endpoint, body)
      raise HTTPError, response unless response.success?

      data = JSON.parse(response.body)
      yield(data) if block_given?
      data
    end
  end

  private

  def trace_jev_call(body, &)
    return yield unless ChatwootApp.otel_enabled?

    traced_jev_call(body, &)
  end

  # Tracing is best-effort: a tracing failure must not block the Jev call or discard a response that already used provider credit.
  def traced_jev_call(body, &)
    outcome = {}
    OpentelemetryConfig.tracer.in_span("llm.#{@feature}.jev", kind: :client) do |span|
      request_model = JSON.parse(body).fetch('model')
      set_request_attributes(span, body, request_model)
      call_in_span(span, outcome, &)
      set_response_attributes(span, outcome[:result], request_model)
    end
    outcome[:result]
  rescue StandardError => e
    raise outcome[:error] if outcome.key?(:error)

    ChatwootExceptionTracker.new(e).capture_exception
    outcome.key?(:result) ? outcome[:result] : yield
  end

  def call_in_span(span, outcome)
    outcome[:result] = yield
  rescue StandardError => e
    outcome[:error] = e
    span.set_attribute('error.type', e.is_a?(HTTPError) ? e.status.to_s : e.class.name)
    span.status = OpenTelemetry::Trace::Status.error(e.class.name)
    raise
  end

  def set_request_attributes(span, body, request_model)
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_TYPE, 'generation')
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, body)
    span.set_attribute(ATTR_LANGFUSE_USER_ID, @account_id.to_s)
    span.set_attribute(ATTR_LANGFUSE_TAGS, [@feature].to_json)
    span.set_attribute(ATTR_GEN_AI_PROVIDER, 'openrouter')
    span.set_attribute('gen_ai.operation.name', 'evaluate')
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, request_model)
    return unless @conversation_id

    session_id = "#{@account_id}_#{@conversation_id}"
    span.set_attribute(ATTR_LANGFUSE_SESSION_ID, session_id)
    span.set_attribute('gen_ai.conversation.id', session_id)
  end

  def set_response_attributes(span, result, request_model)
    usage = result['usage'] || {}
    span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)
    span.set_attribute('langfuse.observation.model.name', result['model'] || request_model)
    span.set_attribute('gen_ai.response.model', result['model']) if result['model']
    span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, usage['input_tokens']) if usage['input_tokens']
    span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, usage['output_tokens']) if usage['output_tokens']
    span.set_attribute('langfuse.observation.cost_details', { total: usage['cost'] }.to_json) if usage['cost'].is_a?(Numeric)
  end

  def connection
    Faraday.new do |client|
      client.options.open_timeout = 3
      client.options.timeout = 15
      client.headers['Authorization'] = "Bearer #{self.class.api_key}"
      client.headers['Content-Type'] = 'application/json'
    end
  end
end
