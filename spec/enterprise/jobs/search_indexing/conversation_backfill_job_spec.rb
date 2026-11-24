require 'rails_helper'

RSpec.describe SearchIndexing::ConversationBackfillJob do
  include_context 'with conversation search queue'

  let(:account) { create(:account) }
  let(:identity) { { 'name' => 'conversation-test', 'uuid' => 'generation-one' } }

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    account.enable_features!('advanced_search_conversations')
    allow(SearchIndexing::IndexVerification).to receive(:identity).and_return(identity)
    allow(Searchkick::ProcessBatchJob).to receive(:perform_now)
  end

  it 'completes bounded native bulk writes across enabled accounts' do
    conversations = create_list(:conversation, 3, account: account)
    other = create(:account)
    other.enable_features!('advanced_search_conversations')
    last = create(:conversation, account: other)
    create(:conversation)

    perform_enqueued_jobs(only: described_class) do
      SearchIndexing::ConversationBackfill.start(all_enabled_accounts: true, batch_size: 2)
    end

    [conversations.first(2), conversations.last(1), [last]].each do |batch|
      expect(Searchkick::ProcessBatchJob).to have_received(:perform_now).with(
        class_name: 'Conversation', record_ids: batch.map { |record| record.id.to_s }, index_name: identity.fetch('name')
      ).once
    end
    expect(account.reload.internal_attributes).not_to have_key(SearchIndexing::IndexVerification::KEY)
  end

  it 'does not advance the cursor after a failed bulk write' do
    create(:conversation, account: account)
    allow(Searchkick::ProcessBatchJob).to receive(:perform_now).and_raise(Searchkick::ImportError, 'rejected item')

    expect do
      described_class.perform_now(account_ids: [account.id], index_identity: identity)
    end.to raise_error(Searchkick::ImportError)
    expect(enqueued_jobs.select { |job| job[:job] == described_class }).to be_empty
  end

  it 'does not apply a disabled account cursor to the next account' do
    other = create(:account)
    other.enable_features!('advanced_search_conversations')
    create(:conversation, account: other)
    account.disable_features!('advanced_search_conversations')

    described_class.perform_now(account_ids: nil, index_identity: identity, cursor: { account_id: account.id, after_id: 10, upper_id: 100 })

    expect(Searchkick::ProcessBatchJob).not_to have_received(:perform_now)
    expect(enqueued_jobs.select { |job| job[:job] == described_class }).to be_empty
  end

  it 'stops if the index was replaced' do
    expect do
      described_class.perform_now(account_ids: [account.id], index_identity: identity.merge('uuid' => 'old'))
    end.to raise_error(/index changed/)
    expect(Searchkick::ProcessBatchJob).not_to have_received(:perform_now)
  end
end
