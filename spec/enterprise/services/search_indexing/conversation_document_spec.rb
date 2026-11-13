require 'rails_helper'

RSpec.describe SearchIndexing::ConversationDocument do
  let(:account) { create(:account) }
  let(:document) { described_class.new(account.id) }

  it 'loads only conversations belonging to the requested account' do
    conversation = create(:conversation, account: account)
    other = create(:conversation)
    expect(document.records([conversation.id, other.id]).pluck(:id)).to eq([conversation.id])
  end

  it 'projects current contact identity and email subject without arbitrary attributes' do
    conversation = create(:conversation, account: account, additional_attributes: { mail_subject: 'Renewal', secret: 'excluded' })
    conversation.contact.update!(name: 'New contact name')
    source = document.serialize(document.records([conversation.id]).sole)
    expect(source['mail_subject']).to eq('Renewal')
    expect(source['contact']['name']).to eq('New contact name')
    expect(source).not_to have_key('additional_attributes')
  end

  it 'does not load a conversation after its contact is removed' do
    conversation = create(:conversation, account: account)
    conversation.contact.destroy!
    expect(document.records([conversation.id])).to be_empty
  end
end
