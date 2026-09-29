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
    account.enable_features!('captain_classifier')
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

  it 'gives Captain the customer attributes as context' do
    create(:custom_attribute_definition, account: account, attribute_model: 'contact_attribute',
                                         attribute_key: 'installation_type', attribute_display_name: 'Installation Type')
    conversation.contact.update!(custom_attributes: { 'installation_type' => 'self-hosted' })
    stub = stub_jev('0' => { 'noul' => 0.8 })

    described_class.new(conditions: [captain_condition], conversation: conversation, message: message).perform

    expect(stub.with do |request|
      body = JSON.parse(request.body)
      body['state']['customer_context'] == { 'contact' => [{ 'name' => 'Installation Type', 'value' => 'self-hosted' }],
                                             'conversation' => [] } &&
        body['questions']['0']['instructions']['question'].include?('`customer_context`')
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

  it 'sends only the start of a very long message' do
    long_message = create(:message, account: account, conversation: conversation, inbox: conversation.inbox,
                                    message_type: :incoming, content: 'refund ' * 3_000)
    stub = stub_jev('0' => { 'noul' => 0.8 })

    described_class.new(conditions: [captain_condition], conversation: conversation, message: long_message).perform

    expect(stub.with do |request|
      JSON.parse(request.body)['state']['latest_message']['text'].length == described_class::LATEST_MESSAGE_LIMIT
    end).to have_been_requested
  end

  context 'when Captain leaves a condition unanswered' do
    let(:conditions) { [captain_condition.merge('query_operator' => 'OR'), captain_condition.merge('filter_operator' => 'does_not_detect')] }
    let(:tracker) { instance_double(ChatwootExceptionTracker, capture_exception: nil) }

    before { allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker) }

    it 'leaves every Captain condition unmet and reports it when an answer is missing' do
      stub_jev('0' => { 'noul' => 0.9 })

      result = described_class.new(conditions: conditions, conversation: conversation, message: message).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(tracker).to have_received(:capture_exception)
    end

    it 'leaves every Captain condition unmet and reports it when an answer has no probability' do
      stub_jev('0' => { 'noul' => 0.9 }, '1' => { 'choice' => 'yes' })

      result = described_class.new(conditions: conditions, conversation: conversation, message: message).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(tracker).to have_received(:capture_exception)
    end
  end

  context 'when the Captain request fails' do
    let(:conditions) { [captain_condition.merge('query_operator' => 'OR'), captain_condition.merge('filter_operator' => 'does_not_detect')] }
    let(:tracker) { instance_double(ChatwootExceptionTracker, capture_exception: nil) }

    before do
      stub_request(:post, endpoint).to_return(status: 500, body: 'upstream error')
      allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)
    end

    it 'leaves every Captain condition unmet and reports the failure' do
      result = described_class.new(conditions: conditions, conversation: conversation, message: message).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(ChatwootExceptionTracker).to have_received(:new).with(instance_of(Captain::JevClient::HTTPError), account: account)
      expect(tracker).to have_received(:capture_exception)
    end

    it 'leaves every Captain condition unmet when the request times out' do
      stub_request(:post, endpoint).to_timeout

      result = described_class.new(conditions: conditions, conversation: conversation, message: message).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(tracker).to have_received(:capture_exception)
    end

    it 'leaves every Captain condition unmet when Jev returns an invalid answer set' do
      stub_request(:post, endpoint).to_return(status: 200, body: { answers: [] }.to_json)

      result = described_class.new(conditions: conditions, conversation: conversation, message: message).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(ChatwootExceptionTracker).to have_received(:new).with(instance_of(described_class::Error), account: account)
      expect(tracker).to have_received(:capture_exception)
    end
  end

  context 'when Captain has nothing it is allowed to judge' do
    let(:conditions) { [captain_condition.merge('query_operator' => 'OR'), captain_condition.merge('filter_operator' => 'does_not_detect')] }

    before { stub_jev('0' => { 'noul' => 0.9 }, '1' => { 'noul' => 0.9 }) }

    it 'leaves every Captain condition unmet for a private note, without sending it' do
      note = create(:message, account: account, conversation: conversation, inbox: conversation.inbox,
                              message_type: :outgoing, private: true, content: 'Customer is on the legacy plan')

      result = described_class.new(conditions: conditions, conversation: conversation, message: note).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(a_request(:post, endpoint)).not_to have_been_made
    end

    it 'leaves every Captain condition unmet for a conversation with no readable message' do
      result = described_class.new(conditions: conditions, conversation: conversation).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(a_request(:post, endpoint)).not_to have_been_made
    end

    it 'leaves every Captain condition unmet once the account no longer has the feature' do
      account.disable_features!('captain_classifier')

      result = described_class.new(conditions: conditions, conversation: conversation, message: message).perform

      expect(result).to eq(0 => false, 1 => false)
      expect(a_request(:post, endpoint)).not_to have_been_made
    end
  end

  it 'does not call Jev when the rule has no Captain condition' do
    result = described_class.new(conditions: [status_condition], conversation: conversation, message: message).perform

    expect(result).to eq({})
    expect(a_request(:post, endpoint)).not_to have_been_made
  end
end
