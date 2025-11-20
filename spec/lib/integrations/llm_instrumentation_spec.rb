require 'rails_helper'

RSpec.describe Integrations::LlmInstrumentation do
  let(:test_class) do
    Class.new do
      include Integrations::LlmInstrumentation
    end
  end

  let(:instance) { test_class.new }

  let!(:otel_config) { create(:installation_config, name: 'OTEL_PROVIDER', value: 'langfuse') }

  describe '#otel_enabled?' do
    context 'when OTEL_PROVIDER is set to langfuse' do
      it 'returns true' do
        expect(instance.send(:otel_enabled?)).to be true
      end
    end

    context 'when OTEL_PROVIDER is empty' do
      before do
        otel_config.update(value: '')
      end

      it 'returns false' do
        expect(instance.send(:otel_enabled?)).to be false
      end
    end

    context 'when OTEL_PROVIDER config does not exist' do
      before do
        otel_config.destroy
      end

      it 'returns false' do
        expect(instance.send(:otel_enabled?)).to be false
      end
    end
  end

  describe '#instrument_llm_call' do
    let(:params) do
      {
        span_name: 'llm.test',
        account_id: 123,
        conversation_id: 456,
        feature_name: 'reply_suggestion',
        model: 'gpt-4o-mini',
        messages: [
          { 'role' => 'user', 'content' => 'Hello' }
        ],
        temperature: 0.7
      }
    end

    context 'when OTEL is disabled' do
      before do
        otel_config.update(value: '')
      end

      it 'yields without creating a span' do
        result = instance.instrument_llm_call(params) { 'test result' }
        expect(result).to eq('test result')
      end
    end

    context 'when OTEL is enabled' do
      let(:mock_span) { instance_double(OpenTelemetry::Trace::Span) }
      let(:mock_tracer) { instance_double(OpenTelemetry::Trace::Tracer) }

      before do
        allow(instance).to receive(:tracer).and_return(mock_tracer)
        allow(mock_tracer).to receive(:in_span).with('llm.test').and_yield(mock_span)
      end

      it 'creates a span and sets request attributes' do
        allow(mock_span).to receive(:set_attribute)

        expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_PROVIDER, 'openai')
        expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_REQUEST_MODEL, 'gpt-4o-mini')
        expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_REQUEST_TEMPERATURE, 0.7)

        instance.instrument_llm_call(params) { { message: 'test' } }
      end

      it 'sets prompt messages' do
        expect(mock_span).to receive(:set_attribute).with('gen_ai.prompt.0.role', 'user')
        expect(mock_span).to receive(:set_attribute).with('gen_ai.prompt.0.content', 'Hello')
        allow(mock_span).to receive(:set_attribute)

        instance.instrument_llm_call(params) { { message: 'test' } }
      end

      it 'sets metadata attributes' do
        expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_LANGFUSE_USER_ID, '123')
        expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_LANGFUSE_SESSION_ID, '456')
        expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_LANGFUSE_TAGS, ['reply_suggestion'].to_json)
        allow(mock_span).to receive(:set_attribute)

        instance.instrument_llm_call(params) { { message: 'test' } }
      end

      context 'when the block returns a successful result' do
        let(:result) do
          {
            message: 'Hello from AI',
            usage: {
              'prompt_tokens' => 10,
              'completion_tokens' => 20,
              'total_tokens' => 30
            }
          }
        end

        it 'sets completion attributes' do
          expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_COMPLETION_ROLE, 'assistant')
          expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_COMPLETION_CONTENT, 'Hello from AI')
          allow(mock_span).to receive(:set_attribute)

          instance.instrument_llm_call(params) { result }
        end

        it 'sets usage metrics' do
          expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_USAGE_INPUT_TOKENS, 10)
          expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_USAGE_OUTPUT_TOKENS, 20)
          expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_USAGE_TOTAL_TOKENS, 30)
          allow(mock_span).to receive(:set_attribute)

          instance.instrument_llm_call(params) { result }
        end
      end

      context 'when the block returns an error result' do
        let(:error_result) do
          {
            error: { 'message' => 'API Error' },
            error_code: 500
          }
        end

        it 'sets error attributes' do
          expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_RESPONSE_ERROR,
                                                            error_result[:error].to_json)
          expect(mock_span).to receive(:set_attribute).with(Integrations::LlmInstrumentation::ATTR_GEN_AI_RESPONSE_ERROR_CODE, 500)
          expect(mock_span).to receive(:status=).with(instance_of(OpenTelemetry::Trace::Status))
          allow(mock_span).to receive(:set_attribute)

          instance.instrument_llm_call(params) { error_result }
        end
      end

      it 'returns the result from the block' do
        allow(mock_span).to receive(:set_attribute)
        result = instance.instrument_llm_call(params) { { message: 'test result' } }
        expect(result).to eq({ message: 'test result' })
      end

      it 'handles errors during instrumentation setup gracefully' do
        allow(instance).to receive(:set_request_attributes).and_raise(StandardError.new('Setup error'))
        allow(Rails.logger).to receive(:error)
        allow(mock_span).to receive(:set_attribute)

        expect(Rails.logger).to receive(:error).with('LLM instrumentation setup error: Setup error')

        result = instance.instrument_llm_call(params) { { message: 'test result' } }
        expect(result).to eq({ message: 'test result' })
      end

      it 'handles errors during completion attributes gracefully' do
        allow(instance).to receive(:set_completion_attributes).and_raise(StandardError.new('Completion error'))
        allow(Rails.logger).to receive(:error)
        allow(mock_span).to receive(:set_attribute)

        expect(Rails.logger).to receive(:error).with('LLM instrumentation completion error: Completion error')

        result = instance.instrument_llm_call(params) { { message: 'test result' } }
        expect(result).to eq({ message: 'test result' })
      end
    end
  end
end
