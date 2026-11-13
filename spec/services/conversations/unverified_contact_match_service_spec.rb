require 'rails_helper'

describe Conversations::UnverifiedContactMatchService do
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
      "- Email: `jane@acme.com`, matches [`Jane Doe`](https://app.chatwoot.com/app/accounts/#{account.id}/contacts/#{email_contact.id})"
    )
    expect(note.content).to include(
      "- Phone: `+14155550123`, matches [`john@acme.com`](https://app.chatwoot.com/app/accounts/#{account.id}/contacts/#{phone_contact.id})"
    )
  end

  it 'links the conversation to the first matched contact and says so in the note' do
    visitor_contact = conversation.contact
    matches = [
      { key: :email, value: 'jane@acme.com', contact: email_contact },
      { key: :phone_number, value: '+14155550123', contact: phone_contact }
    ]

    described_class.new(conversation: conversation, matches: matches).perform

    expect(conversation.reload.contact).to eq email_contact
    expect(conversation.contact_inbox.contact).to eq visitor_contact
    expect(conversation.messages.last.content).to include('We linked this conversation to that contact')
  end

  it 'does not link the conversation when the inbox requires identity validation' do
    conversation.inbox.channel.update!(hmac_mandatory: true)
    visitor_contact = conversation.contact

    described_class.new(conversation: conversation, matches: [{ key: :email, value: 'jane@acme.com', contact: email_contact }]).perform

    expect(conversation.reload.contact).to eq visitor_contact
    expect(conversation.messages.last.content).to include("we didn't link this conversation")
  end

  it 'does not post another note when the conversation is already linked to the matched contact' do
    matches = [{ key: :email, value: 'jane@acme.com', contact: email_contact }]
    described_class.new(conversation: conversation, matches: matches).perform

    expect { described_class.new(conversation: conversation, matches: matches).perform }.not_to change(conversation.messages, :count)
  end

  it 'does not relink a linked conversation to another matched contact' do
    described_class.new(conversation: conversation, matches: [{ key: :email, value: 'jane@acme.com', contact: email_contact }]).perform

    described_class.new(conversation: conversation, matches: [{ key: :phone_number, value: '+14155550123', contact: phone_contact }]).perform

    expect(conversation.reload.contact).to eq email_contact
    expect(conversation.messages.last.content).to include("we didn't link this conversation")
  end

  it 'does not link the conversation when the visitor has their own identifier' do
    conversation.contact.update!(identifier: 'visitor-1')
    visitor_contact = conversation.contact

    described_class.new(conversation: conversation, matches: [{ key: :email, value: 'jane@acme.com', contact: email_contact }]).perform

    expect(conversation.reload.contact).to eq visitor_contact
  end

  it 'labels the link with the phone number when the contact has no name or email' do
    contact = create(:contact, account: account, name: '', identifier: 'customer-1', phone_number: '+14155550123')
    matches = [{ key: :phone_number, value: '+14155550123', contact: contact }]

    described_class.new(conversation: conversation, matches: matches).perform

    expect(conversation.messages.last.content).to include('matches [`+14155550123`](')
  end

  it 'does not let visitor-controlled details add mentions, links or Liquid to the note' do
    agent = create(:user, account: account)
    create(:inbox_member, user: agent, inbox: conversation.inbox)
    contact = create(:contact, account: account, name: "Jane](https://evil.example) [Agent](mention://user/#{agent.id}/Agent) {{contact.email}}")
    matches = [{ key: :email, value: "x{{7}}(mention://user/#{agent.id}/A)@acme.com", contact: contact }]

    described_class.new(conversation: conversation, matches: matches).perform
    note = conversation.messages.last
    Messages::MentionService.new(message: note).perform

    expect(note.content).to include("- Email: `x7mention://user/#{agent.id}/A@acme.com`")
    expect(note.content).to include("matches [`Janehttps://evil.example Agentmention://user/#{agent.id}/Agent contact.email`](")
    expect(conversation.conversation_participants.map(&:user_id)).not_to include(agent.id)
  end

  it 'writes the note in the account locale, not the request locale' do
    account.update!(locale: 'en')
    matches = [{ key: :email, value: 'jane@acme.com', contact: email_contact }]

    I18n.with_locale(:de) { described_class.new(conversation: conversation, matches: matches).perform }

    expect(conversation.messages.last.content).to start_with('This visitor entered contact details')
    expect(conversation.messages.last.content).to include('- Email: `jane@acme.com`')
  end

  it 'adds nothing when there are no matches' do
    expect { described_class.new(conversation: conversation, matches: []).perform }.not_to(change { conversation.messages.count })
  end
end
