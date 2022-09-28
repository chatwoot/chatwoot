require 'rails_helper'

RSpec.describe Imap::ImapMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  describe 'add mail as a new conversation in the email inbox' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent@example.com', account: account) }
    let(:channel) do
      create(:channel_email, imap_enabled: true, imap_address: 'imap.gmail.com',
                             imap_port: 993, imap_login: 'imap@gmail.com', imap_password: 'password',
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
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'testemail@gmail.com', to: 'imap@gmail.com', subject: 'Hello!') }

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
      let(:prev_conversation) { create(:conversation, account: account, inbox: channel.inbox, assignee: agent) }
      let(:reply_mail) do
        create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!', in_reply_to: 'test-in-reply-to')
      end

      it 'appends new email to the existing conversation' do
        create(
          :message,
          content: 'Incoming Message',
          message_type: 'incoming',
          inbox: inbox,
          account: account,
          conversation: prev_conversation
        )
        create(
          :message,
          content: 'Outgoing Message',
          message_type: 'outgoing',
          inbox: inbox,
          source_id: 'test-in-reply-to',
          account: account,
          conversation: prev_conversation
        )

        expect(prev_conversation.messages.size).to eq(2)

        class_instance.process(reply_mail.mail, channel)

        expect(prev_conversation.messages.size).to eq(3)
        expect(prev_conversation.messages.last.content_attributes['email']['from']).to eq(reply_mail.mail.from)
        expect(prev_conversation.messages.last.content_attributes['email']['to']).to eq(reply_mail.mail.to)
        expect(prev_conversation.messages.last.content_attributes['email']['subject']).to eq(reply_mail.mail.subject)
        expect(prev_conversation.messages.last.content_attributes['email']['in_reply_to']).to eq(reply_mail.mail.in_reply_to)
      end
    end

    context 'when a reply for non existing email conversation' do
      let(:reply_mail) do
        create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!', in_reply_to: 'test-in-reply-to')
      end

      it 'creates new email conversation with incoming in-reply-to' do
        class_instance.process(reply_mail.mail, channel)
        expect(conversation.additional_attributes['in_reply_to']).to eq(reply_mail.mail.in_reply_to)
      end
    end
  end
end
