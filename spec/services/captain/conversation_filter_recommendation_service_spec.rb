require 'rails_helper'

RSpec.describe Captain::ConversationFilterRecommendationService do
  subject(:service) { described_class.new(account: account, user: admin, query: query) }

  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:query) { 'urgent unassigned billing chats' }
  let(:endpoint) { 'https://openrouter.ai/api/v1/systemone' }
  let(:answers) { {} }
  # Field order from Captain::ConversationFilterFields: status, priority, assignee_id, inbox_id, team_id,
  # labels, campaign_id, created_at, last_activity_at, then list custom attributes.
  let(:index) { { status: 0, priority: 1, assignee: 2, labels: 5, created_at: 7 } }

  before do
    create(:label, account: account, title: 'billing')
    create(:label, account: account, title: 'shipping')
    Current.account = account
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).and_return(nil)
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('test-key')
    stub_request(:post, endpoint).to_return(
      status: 200, body: { model: 'jev-latest', answers: answers }.to_json, headers: { 'Content-Type' => 'application/json' }
    )
  end

  after { Current.reset }

  def noul(probability)
    { type: 'noul', noul: probability }
  end

  def choice(choice, probability)
    { type: 'choice', choice: choice, probabilities: { choice => probability } }
  end

  context 'when Jev finds relevant fields' do
    let(:answers) do
      {
        "relevant_#{index[:priority]}" => noul(0.9),
        "operator_#{index[:priority]}" => choice('equal_to', 0.9),
        "value_#{index[:priority]}_3" => noul(0.95),
        "relevant_#{index[:assignee]}" => noul(0.8),
        "operator_#{index[:assignee]}" => choice('is_not_present', 0.85),
        "relevant_#{index[:labels]}" => noul(0.2),
        "value_#{index[:labels]}_0" => noul(0.9),
        "relevant_#{index[:status]}" => noul(0.3)
      }
    end

    it 'returns conditions for the account values, most relevant first' do
      expect(service.perform).to eq(
        [
          { attribute_key: 'priority', filter_operator: 'equal_to', values: ['urgent'] },
          { attribute_key: 'labels', filter_operator: 'equal_to', values: ['billing'] },
          { attribute_key: 'assignee_id', filter_operator: 'is_not_present', values: [] }
        ]
      )
    end

    it 'asks every question in one request with the description as state' do
      service.perform

      expect(WebMock).to(have_requested(:post, endpoint).once.with do |request|
        body = JSON.parse(request.body)
        body['state'] == { 'description' => query } &&
          body['questions'].keys.include?("value_#{index[:labels]}_1") &&
          body.dig('questions', "value_#{index[:assignee]}", 'criteria').keys == %w[none option_0]
      end)
    end
  end

  context 'when Jev is unsure of the value or operator' do
    let(:answers) do
      {
        "relevant_#{index[:priority]}" => noul(0.7),
        "operator_#{index[:priority]}" => choice('not_equal_to', 0.4),
        "value_#{index[:priority]}_2" => noul(0.45)
      }
    end

    it 'keeps the field with its first operator and no value' do
      expect(service.perform).to eq([{ attribute_key: 'priority', filter_operator: 'equal_to', values: [] }])
    end
  end

  context 'when the description names several values of one field' do
    let(:query) { 'Status is pending or open' }
    let(:answers) do
      {
        "relevant_#{index[:status]}" => noul(0.9),
        "value_#{index[:status]}_0" => noul(0.92),
        "value_#{index[:status]}_1" => noul(0.03),
        "value_#{index[:status]}_2" => noul(0.88)
      }
    end

    it 'fills in every value Jev is confident of' do
      expect(service.perform).to eq([{ attribute_key: 'status', filter_operator: 'equal_to', values: %w[open pending] }])
    end
  end

  context 'when the description names a single-value field' do
    let(:answers) do
      {
        "relevant_#{index[:assignee]}" => noul(0.9),
        "value_#{index[:assignee]}" => { type: 'choice', choice: 'option_0', probabilities: { 'none' => 0.1, 'option_0' => 0.9 } }
      }
    end

    it 'fills in the option Jev chose' do
      expect(service.perform).to eq([{ attribute_key: 'assignee_id', filter_operator: 'equal_to', values: [admin.id] }])
    end
  end

  context 'when the description asks for conversations older than a number of days' do
    let(:query) { 'conversations created more than 3 days ago' }
    let(:answers) do
      { "relevant_#{index[:created_at]}" => noul(0.9), "operator_#{index[:created_at]}" => choice('days_before', 0.99) }
    end

    it 'uses that number as the days_before value' do
      expect(service.perform).to eq([{ attribute_key: 'created_at', filter_operator: 'days_before', values: [3] }])
    end
  end

  context 'when the description asks for conversations from the last number of days' do
    let(:query) { 'Created in last 3 days' }
    let(:answers) do
      { "relevant_#{index[:created_at]}" => noul(0.96), "operator_#{index[:created_at]}" => choice('is_greater_than', 1.0) }
    end

    it 'compares against the date that many days ago' do
      travel_to Time.zone.parse('2026-11-03 10:00') do
        expect(service.perform).to eq([{ attribute_key: 'created_at', filter_operator: 'is_greater_than', values: ['2026-10-31'] }])
      end
    end
  end

  context 'when the description asks for a range of priorities' do
    let(:query) { 'below high priority' }
    let(:answers) do
      {
        "relevant_#{index[:priority]}" => noul(0.9),
        "operator_#{index[:priority]}" => choice('not_equal_to', 0.8),
        "value_#{index[:priority]}_2" => noul(0.15),
        "range_#{index[:priority]}" => choice('below', 0.99),
        "anchor_#{index[:priority]}" => choice('option_2', 0.95)
      }
    end

    it 'keeps the levels in the range with equal_to' do
      expect(service.perform).to eq([{ attribute_key: 'priority', filter_operator: 'equal_to', values: %w[low medium] }])
    end
  end

  context 'when the description asks for a priority or higher' do
    let(:query) { 'medium or higher priority' }
    let(:answers) do
      {
        "relevant_#{index[:priority]}" => noul(0.95),
        "value_#{index[:priority]}_1" => noul(0.95),
        "range_#{index[:priority]}" => choice('at_or_above', 1.0),
        "anchor_#{index[:priority]}" => choice('option_1', 0.9)
      }
    end

    it 'includes every level from the anchor upwards' do
      expect(service.perform).to eq([{ attribute_key: 'priority', filter_operator: 'equal_to', values: %w[medium high urgent] }])
    end
  end

  context 'when more fields are relevant than the limit' do
    let(:answers) { (0..6).to_h { |field_index| ["relevant_#{field_index}", noul(0.9 - (field_index * 0.01))] } }

    it 'returns only the most relevant ones' do
      expect(service.perform.pluck(:attribute_key)).to eq(%w[status priority assignee_id inbox_id])
    end
  end

  it 'returns nil when Jev fails' do
    stub_request(:post, endpoint).to_return(status: 500, body: 'error')

    expect(service.perform).to be_nil
  end

  it 'returns nil without a request when Jev is not configured' do
    allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return(nil)

    expect(service.perform).to be_nil
    expect(WebMock).not_to have_requested(:post, endpoint)
  end
end
