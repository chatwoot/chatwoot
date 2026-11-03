require 'rails_helper'

RSpec.describe Captain::AutomationEventRecommendation do
  subject(:recommendation) { described_class.new(account: account, query: 'Tag refund requests', events: events) }

  let(:account) { create(:account) }
  let(:events) { %w[conversation_created message_created] }
  let(:endpoint) { 'https://openrouter.ai/api/v1/systemone' }
  let(:event_answer) { { type: 'choice', choice: 'message_created', probabilities: { 'message_created' => 0.9 } } }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).and_return(nil)
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('test-key')
    stub_request(:post, endpoint).to_return(
      status: 200, body: { model: 'jev-latest', answers: { event: event_answer } }.to_json, headers: { 'Content-Type' => 'application/json' }
    )
  end

  it 'returns the event Jev picks from the offered events' do
    expect(recommendation.perform).to eq('message_created')
    expect(WebMock).to(have_requested(:post, endpoint).with do |request|
      JSON.parse(request.body).dig('questions', 'event', 'criteria').keys == %w[conversation_created message_created none]
    end)
  end

  context 'when Jev is unsure' do
    let(:event_answer) { { type: 'choice', choice: 'message_created', probabilities: { 'message_created' => 0.4 } } }

    it 'returns nil' do
      expect(recommendation.perform).to be_nil
    end
  end

  context 'when Jev finds no event' do
    let(:event_answer) { { type: 'choice', choice: 'none', probabilities: { 'none' => 0.9 } } }

    it 'returns nil' do
      expect(recommendation.perform).to be_nil
    end
  end

  it 'returns nil when Jev fails' do
    stub_request(:post, endpoint).to_return(status: 500, body: 'error')

    expect(recommendation.perform).to be_nil
  end
end
