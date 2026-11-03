require 'rails_helper'

describe Conversations::UnverifiedContactNoteService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:email_contact) { create(:contact, account: account, name: 'Jane Doe', email: 'jane@acme.com') }
  let(:phone_contact) { create(:contact, account: account, name: '', email: 'john@acme.com', phone_number: '+14155550123') }

  it 'adds a private note listing each detail and the contact it matched' do
    matches = [
      { key: :email, value: 'jane@acme.com', contact: email_contact },
      { key: :phone_number, value: '+14155550123', contact: phone_contact }
    ]

    with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
      described_class.new(conversation: conversation, matches: matches).perform
    end

    note = conversation.messages.last
    expect(note).to be_private
    expect(note).to be_outgoing
    expect(note.sender).to be_nil
    expect(note.content).to include(
      "- Email: jane@acme.com, matches [Jane Doe](https://app.chatwoot.com/app/accounts/#{account.id}/contacts/#{email_contact.id})"
    )
    expect(note.content).to include(
      "- Phone: +14155550123, matches [john@acme.com](https://app.chatwoot.com/app/accounts/#{account.id}/contacts/#{phone_contact.id})"
    )
  end

  it 'labels the link with the phone number when the contact has no name or email' do
    contact = create(:contact, account: account, name: '', identifier: 'customer-1', phone_number: '+14155550123')
    matches = [{ key: :phone_number, value: '+14155550123', contact: contact }]

    described_class.new(conversation: conversation, matches: matches).perform

    expect(conversation.messages.last.content).to include('matches [+14155550123](')
  end

  it 'writes the note in the account locale, not the request locale' do
    account.update!(locale: 'en')
    matches = [{ key: :email, value: 'jane@acme.com', contact: email_contact }]

    I18n.with_locale(:de) { described_class.new(conversation: conversation, matches: matches).perform }

    expect(conversation.messages.last.content).to start_with('This visitor entered contact details')
    expect(conversation.messages.last.content).to include('- Email: jane@acme.com')
  end

  it 'adds nothing when there are no matches' do
    expect { described_class.new(conversation: conversation, matches: []).perform }.not_to(change { conversation.messages.count })
  end
end
