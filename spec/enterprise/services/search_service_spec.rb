require 'rails_helper'

RSpec.describe SearchService do
  subject(:result) { described_class.new(current_user: user, current_account: account, params: params, search_type: 'Conversation').perform }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:params) { { q: 'renewal' } }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:search) { instance_double(SearchIndexing::ConversationSearch) }

  before do
    Current.account = account
    create(:inbox_member, user: user, inbox: inbox)
    conversation.contact.update!(name: 'Renewal client')
    account.enable_features!('advanced_search', 'advanced_search_conversations')
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    allow(SearchIndexing::ConversationSearch).to receive(:new).and_return(search)
    allow(search).to receive(:perform).and_return(conversations: [], next_cursor: nil, has_more: false)
  end

  after { Current.account = nil }

  it 'does not use contact text matching when both features and OpenSearch are enabled' do
    expect(result[:conversations]).to be_empty
    expect(result[:conversation_search]).to eq(next_cursor: nil, has_more: false)
  end

  it 'includes engine matches without requiring a SQL text match' do
    allow(search).to receive(:perform).and_return(conversations: [conversation], next_cursor: '25', has_more: true)
    expect(result).to eq(conversations: [conversation], conversation_search: { next_cursor: '25', has_more: true })
  end

  %w[advanced_search advanced_search_conversations].each do |feature|
    it "preserves legacy contact matching when #{feature} is disabled" do
      account.disable_features!(feature)
      expect(result[:conversations].pluck(:id)).to eq([conversation.id])
      expect(SearchIndexing::ConversationSearch).not_to have_received(:new)
    end
  end

  it 'preserves legacy contact matching without OpenSearch' do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    expect(result[:conversations].pluck(:id)).to eq([conversation.id])
    expect(SearchIndexing::ConversationSearch).not_to have_received(:new)
  end

  it 'reports availability errors without switching to contact-based SQL results' do
    allow(search).to receive(:perform).and_raise(Faraday::ConnectionFailed)
    expect(result).to eq(conversations: [], conversation_search: { error: true })
  end

  it 'keeps invalid mappings and programming errors visible' do
    allow(search).to receive(:perform).and_raise(OpenSearch::Transport::Transport::Errors::BadRequest)
    expect { result }.to raise_error(OpenSearch::Transport::Transport::Errors::BadRequest)
  end
end
