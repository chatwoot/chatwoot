require 'rails_helper'

RSpec.describe SearchIndexing::Conversations do
  include_context 'with conversation search queue'

  let(:account) { create(:account, internal_attributes: { 'example' => 'retained' }) }
  let(:search_index) do
    Searchkick::Index.new("conversation_reindex_spec_#{SecureRandom.hex(8)}", Conversation.searchkick_options.merge(batch_size: 2))
  end

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    account.enable_features!('advanced_search_conversations')
    allow(search_index).to receive(:exists?).and_return(true)
  end

  it 'queues native bulk jobs in batches for only the requested account, without marking it ready' do
    records = create_list(:conversation, 3, account: account)
    create(:conversation)
    original_attributes = account.reload.attributes

    described_class.reindex_account(account.id)

    jobs = enqueued_jobs.select { |job| job[:job] == Searchkick::BulkReindexJob }
    expect(jobs.map { |job| job[:args].first.fetch('record_ids') }).to eq([records.first(2).map { |record| record.id.to_s }, [records.last.id.to_s]])
    expect(jobs.map { |job| job[:args].first.fetch('index_name') }.uniq).to eq([search_index.name])
    expect(account.reload.attributes).to eq(original_attributes)
  end

  it 'supports rerunning an account without creating or replacing the index' do
    conversation = create(:conversation, account: account)
    2.times { described_class.reindex_account(account.id) }

    expect(Searchkick::BulkReindexJob).to have_been_enqueued.exactly(2).times.with(
      class_name: 'Conversation', record_ids: [conversation.id.to_s], index_name: search_index.name, method_name: nil
    )
  end

  it 'requires the account feature and installation capability' do
    account.disable_features!('advanced_search_conversations')
    expect { described_class.reindex_account(account.id) }.to raise_error(ArgumentError, /enable advanced_search_conversations/)
    account.enable_features!('advanced_search_conversations')
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    expect { described_class.reindex_account(account.id) }.to raise_error(ArgumentError, /Configure OpenSearch/)
    expect(Searchkick::BulkReindexJob).not_to have_been_enqueued
  end

  it 'requires explicit index setup' do
    allow(search_index).to receive(:exists?).and_return(false)
    expect { described_class.reindex_account(account.id) }.to raise_error(Searchkick::Error, /search:setup_conversations/)
    expect(Searchkick::BulkReindexJob).not_to have_been_enqueued
  end
end
