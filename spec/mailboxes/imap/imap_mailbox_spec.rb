require 'rails_helper'

RSpec.describe Imap::ImapMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  describe 'add mail as a new conversation in the email inbox' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent@example.com', account: account) }
    let(:channel) do
      create(:channel_email, imap_enabled: true, imap_address: 'imap.gmail.com',
                             imap_port: 993, imap_email: 'imap@gmail.com', imap_password: 'password',
                             account: account)
    end
    let(:inbox) { create(:inbox, channel: channel, account: account) }
    let!(:contact) { create(:contact, email: 'email@gmail.com', phone_number: '+919584546666', account: account, identifier: '123') }
    let(:conversation) { Conversation.where(inbox_id: channel.inbox).last }
    let(:class_instance) { described_class.new }

    before do
      create(:contact_inbox, contact_id: contact.id, inbox_id: channel.inbox.id)
    end

    context 'when a new email from non existing contact' do
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'newemail@gmail.com', to: 'imap@gmail.com', subject: 'Hello!') }

      it 'creates the contact and conversation with message' do
        class_instance.process(inbound_mail.mail, channel)
        expect(conversation.contact.email).to eq(inbound_mail.mail.from.first)
        expect(conversation.additional_attributes['source']).to eq('email')
        expect(conversation.messages.empty?).to be false
      end
    end

    context 'when a new email from existing contact' do
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!') }

      it 'creates a new conversation with message' do
        class_instance.process(inbound_mail.mail, channel)
        expect(conversation.contact.email).to eq(contact.email)
        expect(conversation.additional_attributes['source']).to eq('email')
        expect(conversation.messages.empty?).to be false
      end
    end

    context 'when a reply for existing email conversation' do
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!', in_reply_to: 'test') }

      it 'appends new email to the existing conversation' do
        class_instance.process(inbound_mail.mail, channel)
      end
    end
  end
end
