# frozen_string_literal: true

require 'agents/instrumentation'

class Captain::Apropos::Instrumentation
  include Integrations::LlmInstrumentationConstants

  TRACE_NAME = 'llm.apropos'
  TAGS = ['apropos'].freeze
  ATTR_GEN_AI_PROVIDER = Integrations::LlmInstrumentationConstants::ATTR_GEN_AI_PROVIDER
  ATTR_GEN_AI_REQUEST_MODEL = Integrations::LlmInstrumentationConstants::ATTR_GEN_AI_REQUEST_MODEL
  ATTR_GEN_AI_USAGE_INPUT_TOKENS = Integrations::LlmInstrumentationConstants::ATTR_GEN_AI_USAGE_INPUT_TOKENS
  ATTR_GEN_AI_USAGE_OUTPUT_TOKENS = Integrations::LlmInstrumentationConstants::ATTR_GEN_AI_USAGE_OUTPUT_TOKENS
  ATTR_LANGFUSE_TAGS = Integrations::LlmInstrumentationConstants::ATTR_LANGFUSE_TAGS
  ATTR_LANGFUSE_OBSERVATION_TYPE = Integrations::LlmInstrumentationConstants::ATTR_LANGFUSE_OBSERVATION_TYPE
  ATTR_LANGFUSE_OBSERVATION_INPUT = Integrations::LlmInstrumentationConstants::ATTR_LANGFUSE_OBSERVATION_INPUT
  ATTR_LANGFUSE_OBSERVATION_OUTPUT = Integrations::LlmInstrumentationConstants::ATTR_LANGFUSE_OBSERVATION_OUTPUT

  class << self
    def install_runner(runner, runtime:, role:)
      return runner unless ChatwootApp.otel_enabled?

      callbacks = TracingCallbacks.new(
        runtime: runtime,
        role: role,
        tracer: OpentelemetryConfig.tracer,
        trace_name: trace_name(role),
        span_attributes: { ATTR_LANGFUSE_TAGS => TAGS.to_json },
        attribute_provider: AttributeProvider.new(runtime, role)
      )
      Agents::CallbackManager::EVENT_TYPES.each do |event|
        runner.public_send("on_#{event}") { |*args| callbacks.public_send("on_#{event}", *args) }
      end
      runner
    rescue StandardError => e
      Rails.logger.warn("[Apropos] Failed to install tracing: #{e.message}")
      runner
    end

    def with_span(name, runtime:, attributes: {}, observation_type: nil, &)
      return yield(nil) unless ChatwootApp.otel_enabled?

      execution = { executed: false }
      span_attributes = runtime.langfuse_attributes.merge(stringify(attributes))
      span_attributes[ATTR_LANGFUSE_OBSERVATION_TYPE] = observation_type if observation_type
      OpentelemetryConfig.tracer.in_span(name, attributes: span_attributes) { |span| execute_operation(span, execution, &) }
      execution[:result]
    rescue StandardError => e
      handle_span_failure(name, e, execution, &)
    end

    def with_agent_tool_context(context_wrapper, &)
      return yield unless ChatwootApp.otel_enabled?

      execution = { executed: false }
      span = context_wrapper&.context&.dig(:__otel_tracing, :current_tool_span)
      return yield unless span

      context = OpenTelemetry::Trace.context_with_span(span)
      OpenTelemetry::Context.with_current(context) { execute_operation(nil, execution, &) }
      execution[:result]
    rescue StandardError => e
      handle_span_failure('tool trace context', e, execution, &)
    end

    def record_generation(runtime:, chat:, message:, model:, role:)
      return unless ChatwootApp.otel_enabled?
      return unless message.respond_to?(:role) && message.role.to_s == 'assistant'

      attributes = {
        ATTR_GEN_AI_PROVIDER => 'openai',
        ATTR_GEN_AI_REQUEST_MODEL => model,
        ATTR_GEN_AI_USAGE_INPUT_TOKENS => message.input_tokens,
        ATTR_GEN_AI_USAGE_OUTPUT_TOKENS => message.output_tokens,
        ATTR_LANGFUSE_OBSERVATION_INPUT => chat_input(chat).to_json
      }
      with_span("#{TRACE_NAME}.#{role}.generation", runtime: runtime, attributes: attributes) do |span|
        set_attributes(span, ATTR_LANGFUSE_OBSERVATION_OUTPUT => generation_output(message).to_json)
      end
    end

    def set_attributes(span, attributes)
      return unless span

      stringify(attributes).each { |key, value| span.set_attribute(key, value) }
    rescue StandardError => e
      Rails.logger.warn("[Apropos] Failed to set tracing attributes: #{e.message}")
    end

    def summary(value)
      case value
      when String
        string_summary(value)
      when Hash
        safe = value.stringify_keys.slice(
          'status', 'error', 'ref', 'result_ref', 'receipts_ref', 'count', 'receipt_count', 'offset', 'next_cursor',
          'query_exhausted', 'truncated', 'bytes', 'value_info'
        )
        { type: 'object', keys: value.keys.map(&:to_s).sort, bytes: value.to_json.bytesize }.merge(safe)
      when Array
        { type: 'array', count: value.size, bytes: value.to_json.bytesize }
      when NilClass, TrueClass, FalseClass, Numeric
        { type: value.class.name.downcase, value: value }
      else
        { type: value.class.name, bytes: value.to_s.bytesize }
      end
    end

    def tool_input(tool_name, arguments)
      values = arguments.respond_to?(:to_h) ? arguments.to_h.stringify_keys : {}
      case tool_name.to_s
      when 'execute'
        { source: values['source'].to_s }
      when 'apropos'
        { query: values['query'].to_s }
      when 'describe'
        { name: values['name'].to_s }
      else
        summary(arguments)
      end
    end

    def generation_output(message)
      calls = if message.respond_to?(:tool_calls) && message.tool_calls.respond_to?(:values)
                message.tool_calls.values.map { |call| { name: call.name.to_s, arguments: tool_input(call.name, call.arguments) } }
              else
                []
              end
      return { tool_calls: calls } if calls.any?

      summary(message.respond_to?(:content) ? message.content : message)
    end

    def chat_input(chat)
      return [] unless chat.respond_to?(:messages)

      chat.messages[0...-1].map { |message| { role: message.role.to_s, content: message.content } }
    end

    def error_from(value)
      payload = value.is_a?(String) ? JSON.parse(value) : value
      return unless payload.is_a?(Hash)

      payload[:error] || payload['error']
    rescue JSON::ParserError
      nil
    end

    private

    def trace_name(role)
      role == 'coordinator' ? TRACE_NAME : "#{TRACE_NAME}.#{role}"
    end

    def stringify(attributes)
      attributes.compact.to_h { |key, value| [key.to_s, scalar(value)] }
    end

    def scalar(value)
      value.is_a?(Hash) || value.is_a?(Array) ? value.to_json : value.to_s
    end

    def record_error(span, error)
      span.record_exception(error)
      span.status = OpenTelemetry::Trace::Status.error(error.message.to_s.truncate(1_000))
    rescue StandardError
      nil
    end

    def string_summary(value)
      summary(JSON.parse(value))
    rescue JSON::ParserError
      { type: 'string', bytes: value.bytesize }
    end

    def execute_operation(span, execution)
      execution[:result] = yield(span)
    rescue StandardError => e
      execution[:error] = e
      record_error(span, e)
      raise
    ensure
      execution[:executed] = true
    end

    def handle_span_failure(name, error, execution)
      raise execution[:error] if execution[:error]

      Rails.logger.warn("[Apropos] Failed to record #{name}: #{error.message}")
      return execution[:result] if execution[:executed]

      yield(nil)
    end
  end
end
