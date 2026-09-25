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

  def trace_jev_call(body)
    return yield unless ChatwootApp.otel_enabled?

    request_model = JSON.parse(body).fetch('model')
    OpentelemetryConfig.tracer.in_span("llm.#{@feature}.jev") do |span|
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_TYPE, 'generation')
      span.set_attribute(ATTR_LANGFUSE_OBSERVATION_INPUT, body)
      span.set_attribute(ATTR_GEN_AI_PROVIDER, 'openrouter')
      span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, request_model)
      span.set_attribute(ATTR_LANGFUSE_USER_ID, @account_id.to_s)
      span.set_attribute(ATTR_LANGFUSE_TAGS, [@feature].to_json)
      span.set_attribute(ATTR_LANGFUSE_SESSION_ID, "#{@account_id}_#{@conversation_id}") if @conversation_id

      begin
        result = yield
        span.set_attribute('langfuse.observation.model.name', result['model'] || request_model)
        span.set_attribute(ATTR_LANGFUSE_OBSERVATION_OUTPUT, result.to_json)
        usage = result['usage'] || {}
        span.set_attribute(ATTR_GEN_AI_USAGE_INPUT_TOKENS, usage['input_tokens']) if usage['input_tokens']
        span.set_attribute(ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, usage['output_tokens']) if usage['output_tokens']
        span.set_attribute('langfuse.observation.cost_details', { total: usage['cost'] }.to_json) if usage['cost'].is_a?(Numeric)
        result
      rescue StandardError => e
        span.status = OpenTelemetry::Trace::Status.error(e.message.truncate(1000))
        raise
      end
    end
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
