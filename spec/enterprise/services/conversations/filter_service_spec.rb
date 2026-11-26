require 'rails_helper'

RSpec.describe Conversations::FilterService do
  subject(:result) { described_class.new(params, user, account).perform }

  include_context 'with conversation search queue'

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:conversation) { create(:conversation, account: account, status: :open) }
  let(:client) { instance_double(OpenSearch::Client) }
  let(:params) do
    { payload: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }],
      sort_by: 'created_at_desc', page: 1 }.with_indifferent_access
  end
  let(:response) do
    { '_shards' => { 'failed' => 0 }, 'hits' => { 'total' => { 'value' => 1, 'relation' => 'eq' }, 'hits' => [{ '_id' => conversation.id.to_s }] },
      'aggregations' => { 'mine' => { 'doc_count' => 0 }, 'unassigned' => { 'doc_count' => 1 } } }
  end

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    account.enable_features!('advanced_search_conversations')
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:search).and_return(response)
  end

  it 'uses indexed rows and aggregations with current SQL authorization' do
    expect(account.internal_attributes).to eq({})
    expect(result[:conversations].map(&:id)).to eq([conversation.id])
    expect(result[:count]).to eq(mine_count: 0, assigned_count: 0, unassigned_count: 1, all_count: 1)
    expect(client).to have_received(:search)
  end

  it 'uses SQL when a candidate no longer matches the filter' do
    response
    conversation.update!(status: :resolved)
    expect(result[:conversations]).to be_empty
    expect(result[:count][:all_count]).to eq(0)
  end

  it 'keeps agents on SQL so permission-sensitive counts stay authoritative' do
    user.account_users.find_by!(account: account).update!(role: :agent)
    expect(result[:count][:all_count]).to eq(0)
    expect(client).not_to have_received(:search)
  end

  it 'uses SQL when the account feature is disabled' do
    conversation
    account.disable_features!('advanced_search_conversations')
    expect(result[:conversations].map(&:id)).to eq([conversation.id])
    expect(client).not_to have_received(:search)
  end

  it 'uses SQL when OpenSearch is not configured' do
    conversation
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    expect(result[:conversations].map(&:id)).to eq([conversation.id])
    expect(client).not_to have_received(:search)
  end

  it 'uses the full SQL request for unsupported sorting' do
    params[:sort_by] = 'priority_desc'
    expect(result[:conversations].map(&:id)).to eq([conversation.id])
    expect(client).not_to have_received(:search)
  end

  context 'with last-message sorting' do
    let(:conversation) do
      create(:conversation, account: account, status: :open, last_message_at: 3.hours.ago, last_activity_at: 5.minutes.ago)
    end
    let!(:recent) { create(:conversation, account: account, last_message_at: 1.hour.ago, last_activity_at: 10.minutes.ago) }
    let!(:tied) { create(:conversation, account: account, last_message_at: recent.reload.last_message_at, last_activity_at: 15.minutes.ago) }
    let!(:notes_only) { create(:conversation, account: account, last_message_at: nil, last_activity_at: Time.current) }

    before do
      account.enable_features!('last_message_sort')
      allow(Conversation).to receive(:default_per_page).and_return(2)
    end

    %w[asc desc].each do |direction|
      context "when ordered #{direction}" do
        let(:params) { super().merge(sort_by: "last_message_at_#{direction}") }
        let(:expected_order) { direction == 'asc' ? [conversation, recent, tied, notes_only] : [tied, recent, conversation, notes_only] }

        it 'uses SQL before pagination, preserving nulls-last and display-ID ties' do
          expect(result[:conversations].to_a).to eq(expected_order.first(2))
          expect(result[:count][:all_count]).to eq(4)
          second_page = described_class.new(params.merge(page: 2), user, account).perform
          expect(second_page[:conversations].to_a).to eq(expected_order.last(2))
          expect(second_page[:count][:all_count]).to eq(4)
          expect(client).not_to have_received(:search)
        end

        it 'uses the default last-activity order when the sort feature is disabled' do
          account.disable_features!('last_message_sort')

          expect(result[:conversations].to_a).to eq([notes_only, conversation])
          expect(client).not_to have_received(:search)
        end
      end
    end
  end

  it 'preserves the ascending order of the legacy creation sort' do
    params[:sort_by] = 'sort_on_created_at'
    result
    expect(client).to have_received(:search).with(hash_including(body: hash_including(sort: [{ 'created_at' => 'asc' }, { id: 'asc' }])))
  end

  it 'keeps a valid empty engine result empty' do
    conversation
    response['hits'] = { 'total' => { 'value' => 0, 'relation' => 'eq' }, 'hits' => [] }
    response['aggregations']['unassigned']['doc_count'] = 0
    expect(result[:conversations]).to be_empty
    expect(result[:count][:all_count]).to eq(0)
  end

  it 'falls back for a partial engine response' do
    response['_shards']['failed'] = 1
    expect(result[:conversations].map(&:id)).to eq([conversation.id])
    expect(result[:count][:all_count]).to eq(1)
  end

  it 'rechecks account ownership when hydrating indexed IDs' do
    other_conversation = create(:conversation)
    response['hits']['hits'] = [{ '_id' => other_conversation.id.to_s }]
    expect(result[:conversations].map(&:id)).to eq([conversation.id])
  end

  it 'uses SQL after engine failure without returning partial counts' do
    allow(client).to receive(:search).and_raise(Faraday::ConnectionFailed)
    expect(result[:conversations].map(&:id)).to eq([conversation.id])
    expect(result[:count][:all_count]).to eq(1)
  end

  it 'preserves validation before attempting indexed filters' do
    params[:payload].first[:filter_operator] = 'contains'
    expect { result }.to raise_error(CustomExceptions::CustomFilter::InvalidOperator)
    expect(client).not_to have_received(:search)
  end
end
