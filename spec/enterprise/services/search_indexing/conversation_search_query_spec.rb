require 'rails_helper'

RSpec.describe SearchIndexing::ConversationSearchQuery do
  let(:account) { build_stubbed(:account) }
  let(:since) { 90.days.ago }
  let(:message_query) { { match: { 'content.analyzed' => 'renewal' } } }
  let(:query) { described_class.new(account, 'renewal', [42], since) }

  before do
    without_partial_double_verification do
      allow(Message).to receive(:search_index).and_return(Searchkick::Index.new('messages_test'))
    end
    allow(Searchkick).to receive(:search).and_return(instance_double(Searchkick::Query, body: { query: message_query }))
  end

  it 'scopes both sources to the tenant and inboxes and groups by the best score' do
    body = query.body
    expect(body[:query][:bool][:filter]).to eq([{ term: { account_id: account.id } }, { terms: { inbox_id: [42] } }])
    expect(body[:collapse]).to eq(field: 'conversation_id')
    expect(body[:sort]).to eq([{ _score: :desc }, { conversation_id: :desc }])
    expect(body[:query][:bool][:should]).to eq([
                                                 { bool: { filter: { term: { _index: Conversation.search_index.name } },
                                                           must: { multi_match: { query: 'renewal', fields: %w[display_id_text mail_subject],
                                                                                  type: 'phrase' } } } },
                                                 { bool: { filter: { term: { _index: 'messages_test' } }, must: message_query } }
                                               ])
    expect(Searchkick).to have_received(:search).with('renewal', model: Message, fields: described_class::MESSAGE_FIELDS,
                                                                 where: { created_at: { gte: since } })
  end
end
