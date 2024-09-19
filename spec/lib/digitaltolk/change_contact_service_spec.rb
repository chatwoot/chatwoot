require 'rails_helper'

describe Digitaltolk::ChangeContactService do
  subject { described_class.new(account, conversation, email) }

  let(:account) { create(:account) }
  let!(:channel_email) { create(:channel_email, account: account) }
  let(:conversation) { create(:conversation, inbox: channel_email.inbox) }
  let(:contact) { conversation.contact }
  let(:email) { Faker::Internet.safe_email }

  it 'changes the contact successfully' do
    contact_inbox = conversation.contact_inbox
    contact = conversation.contact
    contact_inbox.update(source_id: contact.email)

    subject.perform

    conversation.reload
    contact_inbox.reload
    expect(contact_inbox.id).not_to eq(conversation.contact_inbox.id)
    expect(contact.id).not_to eq(conversation.contact.id)
    expect(contact.id).not_to eq(conversation.contact_inbox.contact_id)
    expect(contact.id).to eq(contact_inbox.contact_id)
    expect(contact.email).to eq(contact_inbox.source_id)
  end
end
