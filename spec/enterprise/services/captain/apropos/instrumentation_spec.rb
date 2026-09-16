# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Apropos::Instrumentation do
  let(:fake_span_class) do
    Struct.new(:name, :parent, :attributes, :events, :finished, :status, keyword_init: true) do
      def set_attribute(key, value) = attributes[key] = value
      def record_exception(error) = events << error
      def add_event(name, attributes: {}) = events << [name, attributes]
      def finish = self.finished = true
      def context = OpenTelemetry::Trace::SpanContext::INVALID
    end
  end

  let(:fake_tracer_class) do
    span_class = fake_span_class
    Class.new do
      attr_reader :spans

      define_method(:initialize) { @spans = [] }
      define_method(:start_span) do |name, with_parent: nil, attributes: {}|
        span = span_class.new(name: name, parent: with_parent, attributes: attributes.dup, events: [], finished: false)
        spans << span
        span
      end
      define_method(:in_span) do |name, attributes: {}, &block|
        span = start_span(name, attributes: attributes)
        OpenTelemetry::Context.with_current(OpenTelemetry::Trace.context_with_span(span)) { block.call(span) }
      ensure
        span&.finish
      end
    end
  end

  let(:runtime) do
    instance_double(
      Captain::Apropos::Runtime,
      langfuse_attributes: {
        'langfuse.user.id' => '1',
        'langfuse.session.id' => '22',
        'langfuse.trace.metadata.account_id' => '1',
        'langfuse.trace.metadata.user_id' => '7',
        'langfuse.trace.metadata.turn_id' => 'turn-9'
      },
      run_summary: {
        'langfuse.trace.metadata.agent_calls' => 2,
        'langfuse.trace.metadata.query_calls' => 1,
        'langfuse.trace.metadata.receipt_count' => 1
      }
    )
  end
  let(:tracer) { fake_tracer_class.new }

  before do
    allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
    allow(OpentelemetryConfig).to receive(:tracer).and_return(tracer)
  end

  describe '.install_runner' do
    it 'registers every agent callback and uses the Apropos root trace name' do
      agent = Agents::Agent.new(name: 'Apropos', instructions: 'Help')
      runner = Agents::Runner.with_agents(agent)

      described_class.install_runner(runner, runtime: runtime, role: 'coordinator')

      callbacks = runner.instance_variable_get(:@callbacks)
      expect(callbacks.keys).to match_array(Agents::CallbackManager::EVENT_TYPES)
      expect(callbacks.values).to all(match([be_a(Proc)]))

      context_wrapper = Struct.new(:context).new({ apropos_trace_input: { task: 'count conversations' } })
      callbacks.fetch(:run_start).sole.call('Apropos', 'raw input', context_wrapper)

      expect(tracer.spans.first.name).to eq('llm.apropos')
      expect(tracer.spans.first.attributes).to include(
        'langfuse.trace.metadata.account_id' => '1',
        'langfuse.trace.metadata.user_id' => '7',
        'langfuse.trace.metadata.turn_id' => 'turn-9'
      )
    end

    it 'does nothing when tracing is disabled' do
      allow(ChatwootApp).to receive(:otel_enabled?).and_return(false)
      runner = Agents::Runner.with_agents(Agents::Agent.new(name: 'Apropos', instructions: 'Help'))

      described_class.install_runner(runner, runtime: runtime, role: 'coordinator')

      expect(runner.instance_variable_get(:@callbacks).values).to all(be_empty)
    end
  end

  describe Captain::Apropos::Instrumentation::TracingCallbacks do
    it 'keeps tool and model row contents out of trace attributes' do
      provider = Captain::Apropos::Instrumentation::AttributeProvider.new(runtime, 'coordinator')
      callbacks = described_class.new(runtime: runtime, role: 'coordinator', tracer: tracer, trace_name: 'llm.apropos',
                                      attribute_provider: provider)
      context_wrapper = Struct.new(:context).new({ apropos_trace_input: { task: 'find contacts', input: { type: 'nilclass' } } })
      callbacks.on_run_start('Apropos', 'raw input with secret@example.com', context_wrapper)
      callbacks.on_agent_thinking('Apropos', 'thinking', context_wrapper)
      callbacks.on_tool_start('execute', { source: '(query-data "find contacts")' }, context_wrapper)
      callbacks.on_tool_complete('execute', { result: [{ email: 'secret@example.com' }] }.to_json, context_wrapper)
      callbacks.on_tool_start('describe', { name: 'missing' }, context_wrapper)
      callbacks.on_tool_complete('describe', { error: 'Unknown contract' }.to_json, context_wrapper)

      message_class = Struct.new(:role, :content, :tool_calls, :input_tokens, :output_tokens)
      message = message_class.new(
        :assistant, [{ email: 'secret@example.com' }].to_json, {}, 12, 4
      )
      chat = Struct.new(:messages, :callback) do
        def on_end_message(&block) = self.callback = block
      end.new([
                message_class.new(:system, 'Coordinator system prompt', {}, nil, nil),
                message_class.new(:user, 'Find contacts', {}, nil, nil),
                message
              ], nil)
      callbacks.on_chat_created(chat, 'Apropos', 'gpt-test', context_wrapper, 0)
      chat.callback.call(message)
      result = Struct.new(:output, :error).new([{ email: 'secret@example.com' }], nil)
      callbacks.on_run_complete('Apropos', result, context_wrapper)

      serialized_attributes = tracer.spans.flat_map { |span| span.attributes.values }.join(' ')
      tool_span = tracer.spans.find { |span| span.name == 'llm.apropos.tool.execute' }
      failed_tool_span = tracer.spans.find { |span| span.name == 'llm.apropos.tool.describe' }
      generation_span = tracer.spans.find { |span| span.name == 'llm.apropos.generation' }

      expect(serialized_attributes).not_to include('secret@example.com')
      expect(tool_span.parent).not_to be_nil
      expect(JSON.parse(tool_span.attributes['langfuse.observation.output'])).to include('type' => 'object')
      expect(failed_tool_span.attributes).to include('gen_ai.response.error' => 'Unknown contract')
      expect(failed_tool_span.status).not_to be_nil
      expect(generation_span.attributes).to include(
        'gen_ai.usage.input_tokens' => 12,
        'gen_ai.usage.output_tokens' => 4
      )
      expect(tracer.spans.first.attributes).to include('langfuse.trace.metadata.status' => 'completed')
    end
  end

  describe Captain::Apropos::Instrumentation::AttributeProvider do
    it 'leaves the generation input to the runner instrumentation' do
      provider = described_class.new(runtime, 'coordinator')
      message = Struct.new(:tool_calls).new({})

      attributes = provider.generation_attributes(nil, nil, message)

      expect(attributes).not_to have_key('langfuse.observation.input')
    end
  end

  describe '.chat_input' do
    it 'records the query system and user prompts but excludes the current response' do
      message = Struct.new(:role, :content)
      messages = [
        message.new(:system, 'Query system prompt'),
        message.new(:user, 'Retrieve open conversations'),
        message.new(:assistant, 'Current response')
      ]
      chat = Struct.new(:messages).new(messages)

      expect(described_class.chat_input(chat)).to eq([
                                                       { role: 'system', content: 'Query system prompt' },
                                                       { role: 'user', content: 'Retrieve open conversations' }
                                                     ])
    end
  end

  describe '.with_span' do
    it 'does not repeat an operation that raises' do
      calls = 0

      expect do
        described_class.with_span('llm.apropos.action.test', runtime: runtime) do
          calls += 1
          raise 'operation failed'
        end
      end.to raise_error('operation failed')

      expect(calls).to eq(1)
      expect(tracer.spans.last.events.first.message).to eq('operation failed')
    end

    it 'runs once without tracing when the tracer cannot start a span' do
      failing_tracer = instance_double(OpenTelemetry::Trace::Tracer)
      allow(failing_tracer).to receive(:in_span).and_raise('exporter failed')
      allow(OpentelemetryConfig).to receive(:tracer).and_return(failing_tracer)
      calls = 0

      result = described_class.with_span('llm.apropos.scheme', runtime: runtime) { calls += 1 }

      expect(result).to eq(1)
      expect(calls).to eq(1)
    end
  end

  describe '.with_agent_tool_context' do
    let(:context_wrapper) do
      Struct.new(:context).new({ __otel_tracing: { current_tool_span: fake_span_class.new(attributes: {}, events: []) } })
    end

    it 'does not repeat an operation that raises' do
      calls = 0

      expect do
        described_class.with_agent_tool_context(context_wrapper) do
          calls += 1
          raise 'operation failed'
        end
      end.to raise_error('operation failed')

      expect(calls).to eq(1)
    end

    it 'runs once without the tool context when context setup fails' do
      allow(OpenTelemetry::Trace).to receive(:context_with_span).and_raise('context failed')
      calls = 0

      result = described_class.with_agent_tool_context(context_wrapper) { calls += 1 }

      expect(result).to eq(1)
      expect(calls).to eq(1)
    end
  end
end
