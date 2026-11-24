require 'rails_helper'

RSpec.describe SearchIndexing::IndexVerification do
  let(:account) { create(:account) }
  let(:identity) { { 'name' => 'conversations', 'uuid' => 'first-index' } }

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    allow(described_class).to receive(:identity).and_return(identity)
    account.enable_features!('advanced_search_conversations')
  end

  it 'requires verification for the current index and requested projection version' do
    expect(described_class.ready?(account)).to be(false)
    described_class.record!(account, identity, account_updated_at: account.updated_at)
    expect(described_class.ready?(account)).to be(true)
    expect(described_class.ready?(account, version: 2)).to be(false)
    allow(described_class).to receive(:identity).and_return(identity.merge('uuid' => 'replacement'))
    expect(described_class.ready?(account)).to be(false)
  end

  it 'invalidates verification when disabled through the bulk feature editor' do
    described_class.record!(account, identity, account_updated_at: account.updated_at)
    account.selected_feature_flags = []
    account.save!
    account.enable_features!('advanced_search_conversations')
    expect(described_class.ready?(account.reload)).to be(false)
  end

  it 'rejects verification if the account changed during the scan' do
    previous_update = account.updated_at
    account.disable_features!('advanced_search_conversations')
    account.enable_features!('advanced_search_conversations')
    expect(described_class.record!(account, identity, account_updated_at: previous_update)).to be(false)
  end

  it 'can restore SQL reads while leaving live indexing enabled' do
    described_class.record!(account, identity, account_updated_at: account.updated_at)
    described_class.clear!(account)
    expect(described_class.ready?(account)).to be(false)
    expect(SearchIndexing::Conversations.enabled?(account)).to be(true)
  end
end
