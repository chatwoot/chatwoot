require 'rails_helper'

RSpec.describe Captain::Conversation::TransferPromiseCheck do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:check) { described_class.new(conversation: conversation, reply: 'I am connecting you with our team now.') }
  let(:requests) { [] }

  def stub_jev(probability)
    stub_request(:post, 'https://openrouter.ai/api/v1/systemone').to_return do |request|
      requests << JSON.parse(request.body)
      { status: 200, body: { answers: { transfer: { noul: probability } } }.to_json }
    end
  end

  before do
    allow(ChatwootApp).to receive(:otel_enabled?).and_return(false)
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('test-key')
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).and_return(nil)
    shared = { conversation: conversation, account: account, inbox: conversation.inbox }
    create(:message, **shared, message_type: :incoming, content: 'Can I talk to a person?')
    create(:message, **shared, message_type: :outgoing, private: true, content: 'Internal note')
  end

  it 'asks Jev about the reply with the public messages before it' do
    stub_jev(0.93)

    expect(check.promised?).to be(true)
    expect(requests.first['state']).to eq(
      'conversation' => { 'messages' => [{ 'sender' => 'customer', 'text' => 'Can I talk to a person?' }] },
      'reply' => 'I am connecting you with our team now.'
    )
    expect(requests.first['questions']['transfer']).to eq(described_class::QUESTION.deep_stringify_keys)
  end

  it 'returns false below the threshold' do
    stub_jev(0.2)

    expect(check.promised?).to be(false)
  end

  it 'returns false and reports the error when Jev fails, so the reply still goes out' do
    stub_request(:post, 'https://openrouter.ai/api/v1/systemone').to_return(status: 500, body: 'down')
    exception_tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)

    expect(check.promised?).to be(false)
    expect(exception_tracker).to have_received(:capture_exception)
  end

  it 'returns false when the account has used its Jev quota' do
    allow(ConversationMonitors::Usage).to receive(:new).and_raise(CustomExceptions::JevQuotaError.new('budget_limit', retry_after: 60))

    expect(check.promised?).to be(false)
  end

  describe '.mode' do
    it 'is off without an OpenRouter API key' do
      allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return(nil)
      allow(GlobalConfigService).to receive(:load).with('CAPTAIN_TRANSFER_PROMISE_CHECK_MODE', 'off').and_return('handoff')

      expect(described_class.mode).to eq('off')
    end

    it 'reads the Super Admin setting when the key is present' do
      allow(GlobalConfigService).to receive(:load).with('CAPTAIN_TRANSFER_PROMISE_CHECK_MODE', 'off').and_return('handoff')

      expect(described_class.mode).to eq('handoff')
    end
  end
end
