require 'rails_helper'

RSpec.describe Imap::ImapMailbox do
  include ActionMailbox::TestHelper

  describe '#process' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent@example.com', account: account) }
    let(:channel) { create(:channel_email, :imap_email) }
    let(:inbox) { channel.inbox }
    let!(:contact) { create(:contact, email: 'email@gmail.com', phone_number: '+919584546666', account: account, identifier: '123') }
    let(:conversation) { Conversation.where(inbox_id: channel.inbox).last }
    let(:class_instance) { described_class.new }

    before do
      create(:contact_inbox, contact_id: contact.id, inbox_id: channel.inbox.id)
    end

    context 'when the email is from a new contact' do
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'testemail@gmail.com', to: 'imap@gmail.com', subject: 'Hello!') }

      it 'creates the contact and conversation with message' do
        expect do
          class_instance.process(inbound_mail.mail, channel)
        end.to change(Conversation, :count).by(1)

        expect(conversation.contact.email).to eq(inbound_mail.mail.from.first)
        expect(conversation.additional_attributes['source']).to eq('email')
        expect(conversation.messages.empty?).to be false
      end
    end

    context 'when the email with has empty text content' do
      let(:inbound_mail) { create_inbound_email_from_fixture('attachments_without_text.eml') }

      it 'creates a converstation and a message properly' do
        expect do
          class_instance.process(inbound_mail.mail, channel)
        end.to change(Conversation, :count).by(1)

        expect(conversation.contact.email).to eq(inbound_mail.mail.from.first)
        expect(conversation.messages.last.attachments.count).to be 2
      end
    end

    context 'when the email has attachments with no filename' do
      let(:inbound_mail) { create_inbound_email_from_fixture('attachments_without_filename.eml') }

      it 'creates a conversation and a message with properly named attachments' do
        expect do
          class_instance.process(inbound_mail.mail, channel)
        end.to change(Conversation, :count).by(1)

        last_message = conversation.messages.last
        expect(last_message.attachments.count).to be 2

        filenames = last_message.attachments.map(&:file).map { |file| file.blob.filename.to_s }
        expect(filenames.all? { |filename| filename.present? && filename.start_with?('attachment_') }).to be true
      end
    end

    context 'when the email has 15 or more attachments' do
      let(:inbound_mail) { create_inbound_email_from_fixture('multiple_attachments.eml') }

      it 'creates a converstation and a message properly' do
        expect do
          class_instance.process(inbound_mail.mail, channel)
        end.to change(Conversation, :count).by(1)

        expect(conversation.contact.email).to eq(inbound_mail.mail.from.first)
        expect(conversation.messages.last.attachments.count).to be 15
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

    context 'when a new email with invalid from' do
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'invalidemail', to: 'imap@gmail.com', subject: 'Hello!') }

      it 'does not create a new conversation' do
        expect { class_instance.process(inbound_mail.mail, channel) }.not_to raise_error
      end
    end

    context 'when an auto reply email' do
      let(:auto_reply_mail) { create_inbound_email_from_fixture('auto_reply.eml') }

      it 'does not create a new conversation' do
        expect { class_instance.process(auto_reply_mail.mail, channel) }.not_to change(Conversation, :count)
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

    context 'when a new conversation with nil in_reply_to' do
      let(:prev_conversation) { create(:conversation, account: account, inbox: channel.inbox, assignee: agent) }
      let(:reply_mail) do
        create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!', in_reply_to: nil)
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
          source_id: nil,
          account: account,
          conversation: prev_conversation
        )

        expect(prev_conversation.messages.size).to eq(2)

        class_instance.process(reply_mail.mail, channel)

        expect(prev_conversation.messages.size).to eq(2)

        new_converstion_message = Conversation.last.messages.last.content_attributes
        expect(new_converstion_message['email']['subject']).to eq('Hello!')
      end
    end

    context 'when a reply for non existing email conversation' do
      let(:reply_mail) do
        create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!', in_reply_to: 'test-in-reply-to')
      end
      let(:references_email) { create_inbound_email_from_fixture('references.eml') }

      it 'creates new email conversation with incoming in-reply-to' do
        class_instance.process(reply_mail.mail, channel)
        expect(conversation.additional_attributes['in_reply_to']).to eq(reply_mail.mail.in_reply_to)
      end

      it 'append email to conversation with references id' do
        inbox = Inbox.last
        message = create(
          :message,
          content: 'Incoming Message',
          message_type: 'incoming',
          inbox: inbox,
          source_id: 'test-reference-id',
          account: account,
          conversation: conversation
        )
        conversation = message.conversation

        expect(conversation.messages.size).to eq(1)

        class_instance.process(references_email.mail, inbox.channel)

        expect(conversation.messages.size).to eq(2)
        expect(conversation.messages.last.content).to eq('References Email')
        expect(references_email.mail.references).to include('test-reference-id')
      end

      it 'append email to conversation with reference id string' do
        inbox = Inbox.last
        message = create(
          :message,
          content: 'Incoming Message',
          message_type: 'incoming',
          inbox: inbox,
          source_id: 'test-reference-id-2',
          account: account,
          conversation: conversation
        )
        conversation = message.conversation

        expect(conversation.messages.size).to eq(1)

        references_email.mail.references = 'test-reference-id-2'
        class_instance.process(references_email.mail, inbox.channel)

        expect(conversation.messages.size).to eq(2)
        expect(conversation.messages.last.content).to eq('References Email')
        expect(references_email.mail.references).to include('test-reference-id-2')
      end
    end

    context 'when a reply for a conversation has multiple in_reply_to' do
      let(:multiple_in_reply_to_mail) { create_inbound_email_from_fixture('multiple_in_reply_to.eml').mail }

      it 'creates conversation taking the first in_reply_to email' do
        class_instance.process(multiple_in_reply_to_mail, channel)
        expect(conversation.additional_attributes['in_reply_to']).to eq(multiple_in_reply_to_mail.in_reply_to.first)
      end
    end
  end
end
