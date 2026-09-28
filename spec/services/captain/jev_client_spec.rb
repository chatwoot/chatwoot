require 'rails_helper'

RSpec.describe Captain::JevClient do
  let(:body) { described_class.request_body(model: 'jev-latest', state: { messages: [] }, questions: { test: { type: 'noul' } }) }
  let(:client) { described_class.new(account_id: 7, feature: 'captain_classifier') }

  before do
    allow(ChatwootApp).to receive(:otel_enabled?).and_return(false)
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('test-key')
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).and_return(nil)
  end

  it 'uses the shared default endpoint and returns parsed System One data' do
    response = { model: 'jev-1.13.0', answers: { test: { type: 'noul', noul: 0.9 } } }
    stub_request(:post, 'https://openrouter.ai/api/v1/systemone').to_return(status: 200, body: response.to_json)

    expect(client.call(body: body)).to eq(response.deep_stringify_keys)
    expect(WebMock).to have_requested(:post, 'https://openrouter.ai/api/v1/systemone').with { |request|
      request.headers['Authorization'] == 'Bearer test-key' && JSON.parse(request.body)['model'] == 'jev-latest'
    }.once
  end

  it 'exposes provider status and retry delay for monitor error handling' do
    stub_request(:post, 'https://openrouter.ai/api/v1/systemone')
      .to_return(status: 429, body: 'busy', headers: { 'Retry-After' => '12' })

    expect { client.call(body: body) }.to raise_error(described_class::HTTPError) { |error|
      expect(error.status).to eq(429)
      expect(error.retry_after).to eq(12)
    }
  end

  it 'records the exact request, response, model, usage, and cost in Langfuse' do
    response = { model: 'jev-1.13.0', answers: { test: { type: 'noul', noul: 0.9 } },
                 usage: { input_tokens: 12, output_tokens: 0, cost: 0.000001 } }
    stub_request(:post, 'https://openrouter.ai/api/v1/systemone').to_return(status: 200, body: response.to_json)
    attributes = {}
    span = instance_double(OpenTelemetry::Trace::Span)
    tracer = instance_double(OpenTelemetry::Trace::Tracer)
    allow(span).to receive(:set_attribute) { |name, value| attributes[name] = value }
    allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
    allow(OpentelemetryConfig).to receive(:tracer).and_return(tracer)
    allow(tracer).to receive(:in_span).and_yield(span)

    expect(described_class.new(account_id: 7, conversation_id: 42, feature: 'captain_classifier').call(body: body))
      .to eq(response.deep_stringify_keys)
    expect(tracer).to have_received(:in_span).with('llm.jev.captain_classifier', kind: :client)
    expect(attributes).to include(
      'langfuse.observation.input' => body,
      'langfuse.observation.output' => response.to_json,
      'langfuse.observation.model.name' => 'jev-1.13.0',
      'langfuse.observation.cost_details' => { total: 0.000001 }.to_json,
      'langfuse.session.id' => '7_42',
      'gen_ai.usage.input_tokens' => 12
    )
    expect(WebMock).to have_requested(:post, 'https://openrouter.ai/api/v1/systemone').with(body: body).once
  end

  it 'marks a failed Jev call without retrying it' do
    stub_request(:post, 'https://openrouter.ai/api/v1/systemone').to_timeout
    attributes = {}
    span = instance_double(OpenTelemetry::Trace::Span, 'status=': nil)
    allow(span).to receive(:set_attribute) { |name, value| attributes[name] = value }
    tracer = instance_double(OpenTelemetry::Trace::Tracer)
    allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
    allow(OpentelemetryConfig).to receive(:tracer).and_return(tracer)
    allow(tracer).to receive(:in_span).and_yield(span)

    expect { client.call(body: body) }.to raise_error(Faraday::ConnectionFailed)
    expect(span).to have_received(:status=).with(an_instance_of(OpenTelemetry::Trace::Status))
    expect(WebMock).to have_requested(:post, 'https://openrouter.ai/api/v1/systemone').once
  end

  context 'when tracing fails' do
    let(:response) { { model: 'jev-1.13.0', answers: { test: { type: 'noul', noul: 0.9 } } } }
    let(:tracer) { instance_double(OpenTelemetry::Trace::Tracer) }
    let(:exception_tracker) { instance_double(ChatwootExceptionTracker, capture_exception: nil) }

    before do
      stub_request(:post, 'https://openrouter.ai/api/v1/systemone').to_return(status: 200, body: response.to_json)
      allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
      allow(OpentelemetryConfig).to receive(:tracer).and_return(tracer)
      allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
    end

    it 'keeps the provider response when recording it fails' do
      span = instance_double(OpenTelemetry::Trace::Span)
      allow(span).to receive(:set_attribute) { |name, _| raise 'exporter down' if name == 'langfuse.observation.output' }
      allow(tracer).to receive(:in_span).and_yield(span)

      expect(client.call(body: body)).to eq(response.deep_stringify_keys)
      expect(exception_tracker).to have_received(:capture_exception)
      expect(WebMock).to have_requested(:post, 'https://openrouter.ai/api/v1/systemone').once
    end

    it 'raises the provider error once when recording it fails' do
      stub_request(:post, 'https://openrouter.ai/api/v1/systemone').to_return(status: 429, body: 'busy')
      span = instance_double(OpenTelemetry::Trace::Span, set_attribute: nil)
      allow(span).to receive(:status=).and_raise('exporter down')
      allow(tracer).to receive(:in_span).and_yield(span)

      expect { client.call(body: body) }.to raise_error(described_class::HTTPError)
      expect(WebMock).to have_requested(:post, 'https://openrouter.ai/api/v1/systemone').once
    end

    it 'still calls Jev when the span cannot start' do
      allow(tracer).to receive(:in_span).and_raise('tracer down')

      expect(client.call(body: body)).to eq(response.deep_stringify_keys)
      expect(exception_tracker).to have_received(:capture_exception)
      expect(WebMock).to have_requested(:post, 'https://openrouter.ai/api/v1/systemone').once
    end
  end
end
