require 'rails_helper'

RSpec.describe Captain::ConversationClassifierService do
  let(:conversation) { create(:conversation) }
  let(:endpoint) { 'https://openrouter.ai/api/v1/systemone' }
  let(:response) do
    { model: 'jev-1.13.0', answers: { priority: { type: 'choice', choice: 'medium', confidence: 0.8 } },
      usage: { input_tokens: 15, output_tokens: 0 } }
  end

  before do
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil)
                                                .and_return('https://openrouter.ai/api')
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('test-key')
    stub_request(:post, endpoint).to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'records the classifier request as a Jev generation without changing its answer' do
    span = instance_double(OpenTelemetry::Trace::Span, set_attribute: nil)
    tracer = instance_double(OpenTelemetry::Trace::Tracer)
    allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
    allow(OpentelemetryConfig).to receive(:tracer).and_return(tracer)
    allow(tracer).to receive(:in_span).and_yield(span)

    result = described_class.new(conversation: conversation).priority

    expect(result).to eq(priority: 'medium', confidence: 0.8)
    expect(tracer).to have_received(:in_span).with('llm.captain_classifier.jev')
    expect(span).to have_received(:set_attribute).with('langfuse.session.id', "#{conversation.account_id}_#{conversation.display_id}")
    expect(span).to have_received(:set_attribute).with('gen_ai.usage.input_tokens', 15)
    expect(WebMock).to have_requested(:post, endpoint).once
  end

  it 'preserves the classifier error on an unsuccessful Jev response' do
    stub_request(:post, endpoint).to_return(status: 401, body: 'invalid key')

    expect { described_class.new(conversation: conversation).priority }
      .to raise_error(described_class::Error, 'Jev request failed with status 401: invalid key')
    expect(WebMock).to have_requested(:post, endpoint).once
  end
end
