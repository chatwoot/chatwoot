require 'rails_helper'

RSpec.describe Captain::AutomationConditionService do
  let(:endpoint) { 'https://openrouter.example/v1/systemone' }
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) do
    create(:message, account: account, conversation: conversation, inbox: conversation.inbox,
                     message_type: :incoming, content: 'I want my money back')
  end
  let(:status_condition) { { 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'], 'query_operator' => 'AND' } }
  let(:captain_condition) do
    { 'attribute_key' => 'captain_condition', 'filter_operator' => 'detects',
      'values' => ['the customer is asking for a refund'], 'query_operator' => nil }
  end

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).and_return('https://openrouter.example')
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('secret-key')
  end

  def stub_jev(answers)
    stub_request(:post, endpoint).to_return(status: 200, body: { answers: answers }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'asks one question per Captain condition, keyed by its position in the rule' do
    stub = stub_jev('1' => { 'noul' => 0.8 })

    result = described_class.new(conditions: [status_condition, captain_condition], conversation: conversation, message: message).perform

    expect(result).to eq(1 => true)
    expect(stub).to have_been_requested
    expect(stub.with do |request|
      body = JSON.parse(request.body)
      body['questions'].keys == ['1'] &&
        body['questions']['1']['type'] == 'noul' &&
        body['questions']['1']['instructions']['description'] == 'the customer is asking for a refund' &&
        body['state']['latest_message'] == { 'sender' => 'customer', 'text' => 'I want my money back' } &&
        body['state']['conversation']['messages'].pluck('text') == ['I want my money back']
    end).to have_been_requested
  end

  it 'treats a probability below the threshold as not detected' do
    stub_jev('1' => { 'noul' => 0.2 })

    result = described_class.new(conditions: [status_condition, captain_condition], conversation: conversation, message: message).perform

    expect(result).to eq(1 => false)
  end

  it 'inverts the answer for does_not_detect' do
    stub_jev('0' => { 'noul' => 0.8 })
    condition = captain_condition.merge('filter_operator' => 'does_not_detect')

    result = described_class.new(conditions: [condition], conversation: conversation, message: message).perform

    expect(result).to eq(0 => false)
  end

  it 'judges the whole conversation when the event has no message' do
    message
    stub = stub_jev('0' => { 'noul' => 0.8 })

    described_class.new(conditions: [captain_condition], conversation: conversation).perform

    expect(stub.with do |request|
      body = JSON.parse(request.body)
      !body['state'].key?('latest_message') && body['state']['conversation']['messages'].pluck('text') == ['I want my money back']
    end).to have_been_requested
  end

  it 'does not call Jev when the rule has no Captain condition' do
    result = described_class.new(conditions: [status_condition], conversation: conversation, message: message).perform

    expect(result).to eq({})
    expect(a_request(:post, endpoint)).not_to have_been_made
  end
end
