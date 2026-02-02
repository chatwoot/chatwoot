require 'rails_helper'

RSpec.describe Integrations::LlmInstrumentation do
  let(:test_class) do
    Class.new do
      include Integrations::LlmInstrumentation
    end
  end

  let(:instance) { test_class.new }
  let!(:otel_config) do
    InstallationConfig.find_or_create_by(name: 'OTEL_PROVIDER') do |config|
      config.value = 'langfuse'
    end
  end

  let(:params) do
    {
      span_name: 'llm.test',
      account_id: 123,
      conversation_id: 456,
      feature_name: 'reply_suggestion',
      model: 'gpt-4o-mini',
      messages: [{ 'role' => 'user', 'content' => 'Hello' }],
      temperature: 0.7
    }
  end

  before do
    InstallationConfig.find_or_create_by(name: 'LANGFUSE_SECRET_KEY') do |config|
      config.value = 'test-secret-key'
    end
  end

  describe '#instrument_llm_call' do
    context 'when OTEL provider is not configured' do
      before { otel_config.update(value: '') }

      it 'executes the block without tracing' do
        result = instance.instrument_llm_call(params) { 'my_result' }
        expect(result).to eq('my_result')
      end
    end

    context 'when OTEL provider is configured' do
      it 'executes the block and returns the result' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        result = instance.instrument_llm_call(params) { 'my_result' }

        expect(result).to eq('my_result')
      end

      it 'creates a tracing span with the provided span name' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        instance.instrument_llm_call(params) { 'result' }

        expect(mock_tracer).to have_received(:in_span).with('llm.test')
      end

      it 'returns the block result even if instrumentation has errors' do
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_raise(StandardError.new('Instrumentation failed'))

        result = instance.instrument_llm_call(params) { 'my_result' }

        expect(result).to eq('my_result')
      end

      it 'handles errors gracefully and captures exceptions' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)
        allow(mock_span).to receive(:set_attribute).and_raise(StandardError.new('Span error'))
        allow(ChatwootExceptionTracker).to receive(:new).and_call_original

        result = instance.instrument_llm_call(params) { 'my_result' }

        expect(result).to eq('my_result')
        expect(ChatwootExceptionTracker).to have_received(:new)
      end

      it 'sets correct request attributes on the span' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        instance.instrument_llm_call(params) { 'result' }

        expect(mock_span).to have_received(:set_attribute).with('gen_ai.provider.name', 'openai')
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.request.model', 'gpt-4o-mini')
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.request.temperature', 0.7)
      end

      it 'sets correct prompt message attributes' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        custom_params = params.merge(
          messages: [
            { 'role' => 'system', 'content' => 'You are a helpful assistant' },
            { 'role' => 'user', 'content' => 'Hello' }
          ]
        )

        instance.instrument_llm_call(custom_params) { 'result' }

        expect(mock_span).to have_received(:set_attribute).with('gen_ai.prompt.0.role', 'system')
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.prompt.0.content', 'You are a helpful assistant')
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.prompt.1.role', 'user')
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.prompt.1.content', 'Hello')
      end

      it 'sets correct metadata attributes' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        instance.instrument_llm_call(params) { 'result' }

        expect(mock_span).to have_received(:set_attribute).with('langfuse.user.id', '123')
        expect(mock_span).to have_received(:set_attribute).with('langfuse.session.id', '123_456')
        expect(mock_span).to have_received(:set_attribute).with('langfuse.trace.tags', '["reply_suggestion"]')
      end

      it 'sets completion message attributes when result contains message' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        result = instance.instrument_llm_call(params) do
          { message: 'AI response here' }
        end

        expect(result).to eq({ message: 'AI response here' })
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.completion.0.role', 'assistant')
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.completion.0.content', 'AI response here')
      end

      it 'sets usage metrics when result contains usage data' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        result = instance.instrument_llm_call(params) do
          {
            usage: {
              'prompt_tokens' => 150,
              'completion_tokens' => 200,
              'total_tokens' => 350
            }
          }
        end

        expect(result[:usage]['prompt_tokens']).to eq(150)
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.usage.input_tokens', 150)
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.usage.output_tokens', 200)
        expect(mock_span).to have_received(:set_attribute).with('gen_ai.usage.total_tokens', 350)
      end

      it 'sets error attributes when result contains error' do
        mock_span = instance_double(OpenTelemetry::Trace::Span)
        mock_status = instance_double(OpenTelemetry::Trace::Status)
        allow(mock_span).to receive(:set_attribute)
        allow(mock_span).to receive(:status=)
        allow(OpenTelemetry::Trace::Status).to receive(:error).and_return(mock_status)
        mock_tracer = instance_double(OpenTelemetry::Trace::Tracer)
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).and_yield(mock_span)

        result = instance.instrument_llm_call(params) do
          {
            error: 'API rate limit exceeded'
          }
        end

        expect(result[:error]).to eq('API rate limit exceeded')
        expect(mock_span).to have_received(:set_attribute)
          .with('gen_ai.response.error', '"API rate limit exceeded"')
        expect(mock_span).to have_received(:status=).with(mock_status)
        expect(OpenTelemetry::Trace::Status).to have_received(:error).with('API rate limit exceeded')
      end
    end

    describe '#instrument_agent_session' do
      context 'when OTEL provider is not configured' do
        before { otel_config.update(value: '') }

        it 'executes the block without tracing' do
          result = instance.instrument_agent_session(params) { 'my_result' }
          expect(result).to eq('my_result')
        end
      end

      context 'when OTEL provider is configured' do
        let(:mock_span) { instance_double(OpenTelemetry::Trace::Span) }
        let(:mock_tracer) { instance_double(OpenTelemetry::Trace::Tracer) }

        before do
          allow(mock_span).to receive(:set_attribute)
          allow(instance).to receive(:tracer).and_return(mock_tracer)
          allow(mock_tracer).to receive(:in_span).and_yield(mock_span)
        end

        it 'executes the block and returns the result' do
          result = instance.instrument_agent_session(params) { 'my_result' }
          expect(result).to eq('my_result')
        end

        it 'returns the block result even if instrumentation has errors' do
          allow(mock_tracer).to receive(:in_span).and_raise(StandardError.new('Instrumentation failed'))

          result = instance.instrument_agent_session(params) { 'my_result' }

          expect(result).to eq('my_result')
        end

        it 'sets trace input and output attributes' do
          result_data = { content: 'AI response' }
          instance.instrument_agent_session(params) { result_data }

          expect(mock_span).to have_received(:set_attribute).with('langfuse.observation.input', params[:messages].to_json)
          expect(mock_span).to have_received(:set_attribute).with('langfuse.observation.output', result_data.to_json)
        end

        # Regression test for Langfuse double-counting bug.
        # Setting gen_ai.request.model on parent spans causes Langfuse to classify them as
        # GENERATIONs instead of SPANs, resulting in cost being counted multiple times
        # (once for the parent, once for each child GENERATION).
        # See: https://github.com/langfuse/langfuse/issues/7549
        it 'does NOT set gen_ai.request.model to avoid being classified as a GENERATION' do
          instance.instrument_agent_session(params) { 'result' }

          expect(mock_span).not_to have_received(:set_attribute).with('gen_ai.request.model', anything)
        end
      end
    end
  end
end
