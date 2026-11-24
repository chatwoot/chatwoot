require 'rails_helper'

RSpec.describe SearchService do
  subject(:results) do
    described_class.new(current_user: user, current_account: account, params: { q: 'renewal' }, search_type: 'Conversation').perform[:conversations]
  end

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
end
