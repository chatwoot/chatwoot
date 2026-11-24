require 'rails_helper'

RSpec.describe SearchService do
  subject(:results) do
    described_class.new(current_user: user, current_account: account, params: { q: query }, search_type: 'Conversation').perform[:conversations]
  end

  let(:query) { 'renewal' }
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:matching) { create(:conversation, account: account, inbox: inbox, additional_attributes: { mail_subject: 'Renewal reminder' }) }
  let(:candidate_search) { instance_double(SearchIndexing::ConversationSearch) }

  before do
    Current.account = account
    create(:inbox_member, inbox: inbox, user: user)
    allow(SearchIndexing::ConversationSearch).to receive(:new).and_return(candidate_search)
  end

  after { Current.account = nil }

  it 'rechecks current tenant, inbox access and matching against candidate IDs' do
    inaccessible = create(:conversation, account: account, additional_attributes: { mail_subject: 'Renewal' })
    other_tenant = create(:conversation, additional_attributes: { mail_subject: 'Renewal' })
    stale = create(:conversation, account: account, inbox: inbox, additional_attributes: { mail_subject: 'Unrelated' })
    allow(candidate_search).to receive(:ids).and_return([matching.id, inaccessible.id, other_tenant.id, stale.id])

    expect(results.pluck(:id)).to eq([matching.id])
  end

  it 'preserves SQL results on fallback' do
    matching
    allow(candidate_search).to receive(:ids).and_return(nil)
    expect(results.pluck(:id)).to eq([matching.id])
  end

  it 'does not turn a valid empty candidate list into SQL results' do
    matching
    allow(candidate_search).to receive(:ids).and_return([])
    expect(results).to be_empty
  end

  { name: 'Renewal client', email: 'renewal@example.com', identifier: 'renewal-reference', phone_number: '+15554567890' }.each do |field, value|
    context "when only the contact #{field} matches" do
      let(:query) { field == :phone_number ? '456789' : 'renewal' }

      it 'finds the conversation through SQL without an indexed contact document' do
        conversation = create(:conversation, account: account, inbox: inbox)
        conversation.contact.update!(field => value)
        allow(candidate_search).to receive(:ids).and_return([])
        expect(results.pluck(:id)).to eq([conversation.id])
      end
    end
  end

  it 'includes current contact changes without waiting for a conversation reindex' do
    conversation = create(:conversation, account: account, inbox: inbox)
    allow(candidate_search).to receive(:ids).and_return([])
    expect(results).to be_empty
    conversation.contact.update!(name: 'Renewal client')
    expect(results.reload.pluck(:id)).to eq([conversation.id])
  end

  it 'keeps contact matches scoped to the current account and accessible inboxes' do
    inaccessible = create(:conversation, account: account)
    inaccessible.contact.update!(name: 'Renewal client')
    other_account = create(:conversation)
    other_account.contact.update!(name: 'Renewal client')
    allow(candidate_search).to receive(:ids).and_return([])
    expect(results).to be_empty
  end
end
