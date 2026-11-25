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

    context 'when reply-to contains an empty quoted address' do
      let(:inbound_mail) { create_inbound_email_from_fixture('malformed_reply_to.eml') }
      let(:mail) { inbound_mail.mail }

      it 'creates a conversation and message using the valid from address' do
        expect(mail.reply_to).to eq([nil])

        expect do
          class_instance.process(mail, channel)
        end.to change(Conversation, :count).by(1).and change(Message, :count).by(1)

        expect(conversation.contact.email).to eq('sender@example.com')
        expect(conversation.messages.last.content_attributes.dig('email', 'from')).to eq(['sender@example.com'])
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

    context 'when the email has inline attachments other than images' do
      let(:inbound_mail) { create_inbound_email_from_fixture('email_with_inline_pdf.eml') }

      it 'creates a conversation and a message with non-image files as regular attachments' do
        expect do
          class_instance.process(inbound_mail.mail, channel)
        end.to change(Conversation, :count).by(1)

        last_message = conversation.messages.last
        expect(last_message.attachments.count).to be 1

        attachment = last_message.attachments.first
        expect(attachment.file.blob.filename.to_s).to eq 'dummy.pdf'
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

    context 'when another fetch job has already saved the email' do
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!') }

      it 'does not create a second conversation or message' do
        create(:message, account: account, inbox: inbox, source_id: inbound_mail.mail.message_id)

        expect do
          class_instance.process(inbound_mail.mail, channel)
        end.to not_change(Conversation, :count).and not_change(Message, :count)
      end
    end

    context 'when another fetch job saves the email after this job cached its fetch-stage duplicate check' do
      let(:inbound_mail) { create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Hello!') }
      let(:message_id) { inbound_mail.mail.message_id }

      it 'does not create a second conversation or message' do
        ActiveRecord::Base.cache do
          inbox.messages.exists?(source_id: message_id)
          # The other job writes on its own connection, so this job's query cache is not cleared
          ActiveRecord::Base.uncached(dirties: false) { create(:message, account: account, inbox: inbox, source_id: message_id) }

          class_instance.process(inbound_mail.mail, channel)
        end

        expect(inbox.messages.where(source_id: message_id).count).to eq(1)
        expect(inbox.conversations.count).to eq(1)
      end
    end

    context 'when a new email contains null bytes' do
      let(:inbound_mail) do
        Mail.new.tap do |mail|
          mail.from = 'email@gmail.com'
          mail.to = 'imap@gmail.com'
          mail.subject = "Hello\u0000"
          mail.message_id = "message\u0000@example.com"
          mail['In-Reply-To'] = "source\u0000@example.com"
          mail.references = ["reference\u0000@example.com"]
          mail.content_type = 'text/plain'
          mail.body = "Body\u0000 text"
        end
      end

      it 'creates sanitized conversation and message records' do
        expect { class_instance.process(inbound_mail, channel) }.to change(Conversation, :count).by(1)

        message = conversation.messages.last

        expect(conversation.additional_attributes['in_reply_to']).to eq('source@example.com')
        expect(conversation.additional_attributes['mail_subject']).to eq('Hello')
        expect(message.source_id).to eq('message@example.com')
        expect(message.content).to eq('Body text')
        expect(message.content_attributes.to_json).not_to include('\u0000')
      end
    end

    context 'when the subject is longer than the generic jsonb limit' do
      let(:inbound_mail) do
        Mail.new.tap do |mail|
          mail.from = 'email@gmail.com'
          mail.to = 'imap@gmail.com'
          # A customer who types the whole request into the subject field, which is what phone
          # mail clients invite. It used to raise RecordInvalid and the fetcher dropped the
          # email without a trace.
          mail.subject = 'a' * 1972
          mail.message_id = 'long-subject@example.com'
          mail.content_type = 'text/plain'
          mail.body = 'Sent from my iPhone'
        end
      end

      it 'creates the conversation keeping the subject whole' do
        expect { class_instance.process(inbound_mail, channel) }.to change(Conversation, :count).by(1)

        expect(conversation.additional_attributes['mail_subject']).to eq(inbound_mail.subject)
      end
    end

    context 'when the subject is longer than even the mail_subject allowance' do
      let(:inbound_mail) do
        Mail.new.tap do |mail|
          mail.from = 'email@gmail.com'
          mail.to = 'imap@gmail.com'
          mail.subject = 'a' * (JsonbAttributesLengthValidator::KEY_MAX_STRING_LENGTH[:additional_attributes]['mail_subject'] + 1)
          mail.message_id = 'huge-subject@example.com'
          mail.content_type = 'text/plain'
          mail.body = 'Sent from my iPhone'
        end
      end

      it 'still refuses it, so the payload stays bounded' do
        expect { class_instance.process(inbound_mail, channel) }.to raise_error(ActiveRecord::RecordInvalid)
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
        expect { class_instance.process(auto_reply_mail.mail, channel) }.to change(Conversation, :count)
        expect(Conversation.last.additional_attributes['auto_reply']).to be true
      end
    end

    context 'when the email is bounced' do
      let!(:bounced_mail) { create_inbound_email_from_fixture('bounced_gmail.eml') }

      it 'processes the bounced email' do
        expect { class_instance.process(bounced_mail.mail, channel) }.to change(Message, :count)
        expect(Message.last.content_attributes['email']['auto_reply']).to be true
        expect(Conversation.last.additional_attributes['auto_reply']).to be true
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

    context 'when a reply to a forwarded email' do
      let(:prev_conversation) { create(:conversation, account: account, inbox: channel.inbox, assignee: agent) }
      let(:supplier_reply) do
        create_inbound_email_from_mail(from: 'supplier@example.com', to: 'imap@gmail.com', subject: 'Re: Fwd: Hello!',
                                       in_reply_to: '<forward/1@example.com>')
      end

      before do
        create(:message, conversation: prev_conversation, account: account, inbox: inbox, message_type: :outgoing,
                         source_id: 'forward/1@example.com', content_attributes: { forwarded_message_id: 1, to_emails: ['supplier@example.com'] })
      end

      it 'starts a new conversation with the forward recipient instead of using the original conversation' do
        expect { class_instance.process(supplier_reply.mail, channel) }.to change(Conversation, :count).by(1)

        expect(prev_conversation.messages.incoming).to be_empty
        expect(conversation.contact.email).to eq('supplier@example.com')
      end

      it 'keeps further replies from the same recipient in their conversation' do
        class_instance.process(supplier_reply.mail, channel)
        second_reply = create_inbound_email_from_mail(from: 'supplier@example.com', to: 'imap@gmail.com', subject: 'Re: Fwd: Hello!',
                                                      in_reply_to: '<forward/1@example.com>')

        expect { class_instance.process(second_reply.mail, channel) }.not_to change(Conversation, :count)
        expect(conversation.messages.incoming.count).to eq(2)
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

    context 'when a reply to a conversation started by an agent' do
      let(:agent_conversation) { create(:conversation, account: account, inbox: channel.inbox, assignee: agent) }
      let(:reply_mail_with_fallback_reference) do
        # Simulate an email reply with a reference that matches FALLBACK_PATTERN
        reference_id = "account/#{account.id}/conversation/#{agent_conversation.uuid}@chatwoot.com"
        create_inbound_email_from_mail(
          from: 'email@gmail.com',
          to: 'imap@gmail.com',
          subject: 'Re: Agent started conversation',
          references: [reference_id]
        )
      end

      it 'appends email to the existing conversation using FALLBACK_PATTERN' do
        expect(agent_conversation.messages.size).to eq(0)

        class_instance.process(reply_mail_with_fallback_reference.mail, channel)

        agent_conversation.reload
        expect(agent_conversation.messages.size).to eq(1)
        expect(agent_conversation.messages.last.content_attributes['email']['from']).to eq(reply_mail_with_fallback_reference.mail.from)
      end
    end

    context 'when references contain both message and fallback patterns' do
      let(:agent_conversation) { create(:conversation, account: account, inbox: channel.inbox, assignee: agent) }
      let(:reply_mail_with_multiple_references) do
        # Multiple references including both patterns
        fallback_reference = "account/#{account.id}/conversation/#{agent_conversation.uuid}@chatwoot.com"
        other_reference = 'some-other-message-id@example.com'
        create_inbound_email_from_mail(
          from: 'email@gmail.com',
          to: 'imap@gmail.com',
          subject: 'Re: Multiple references',
          references: [other_reference, fallback_reference]
        )
      end

      it 'finds conversation using fallback pattern when message lookup fails' do
        expect(agent_conversation.messages.size).to eq(0)

        class_instance.process(reply_mail_with_multiple_references.mail, channel)

        agent_conversation.reload
        expect(agent_conversation.messages.size).to eq(1)
        expect(agent_conversation.messages.last.content_attributes['email']['from']).to eq(reply_mail_with_multiple_references.mail.from)
      end
    end

    # An inbox that continues the contact's open case. Headers still decide first: what changes is
    # only the mail that references nothing, which used to open a second conversation about a case
    # nobody had closed.
    context 'when the inbox continues the contact\'s open case' do
      let(:channel) { create(:channel_email, :imap_email, continue_open_conversation: true) }
      let(:fresh_mail) do
        create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Reembolso')
      end

      it 'lands in the open conversation instead of starting another one' do
        open_conversation = create(:conversation, account: account, inbox: channel.inbox, contact: contact, status: :open)

        expect { class_instance.process(fresh_mail.mail, channel) }.not_to change(Conversation, :count)

        expect(open_conversation.reload.messages.size).to eq(1)
      end

      it 'starts a new conversation when the previous one is resolved' do
        create(:conversation, account: account, inbox: channel.inbox, contact: contact, status: :resolved)

        expect { class_instance.process(fresh_mail.mail, channel) }.to change(Conversation, :count).by(1)
      end

      it 'lands in the most recent open conversation when the contact has several' do
        create(:conversation, account: account, inbox: channel.inbox, contact: contact, status: :open)
        newest = create(:conversation, account: account, inbox: channel.inbox, contact: contact, status: :open)

        class_instance.process(fresh_mail.mail, channel)

        expect(newest.reload.messages.size).to eq(1)
      end

      # The header is positive proof of which case this is, and it outranks the policy. A reply to
      # a resolved thread goes back to that thread, which is also what reopens it.
      it 'still follows in-reply-to into a resolved conversation' do
        resolved = create(:conversation, account: account, inbox: channel.inbox, contact: contact, status: :resolved)
        create(:message, content: 'Outgoing', message_type: 'outgoing', inbox: inbox, source_id: 'ref-to-resolved',
                         account: account, conversation: resolved)
        create(:conversation, account: account, inbox: channel.inbox, contact: contact, status: :open)
        reply = create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Re: Reembolso',
                                               in_reply_to: 'ref-to-resolved')

        expect { class_instance.process(reply.mail, channel) }.not_to change(Conversation, :count)

        expect(resolved.reload.messages.size).to eq(2)
        expect(resolved).to be_open
      end

      it 'ignores conversations the contact has in another inbox' do
        other_channel = create(:channel_email, :imap_email, continue_open_conversation: true)
        create(:contact_inbox, contact_id: contact.id, inbox_id: other_channel.inbox.id)
        create(:conversation, account: account, inbox: other_channel.inbox, contact: contact, status: :open)

        expect { class_instance.process(fresh_mail.mail, channel) }.to change(Conversation, :count).by(1)
      end
    end

    # The default, which is every inbox that has not asked for anything else.
    context 'when the inbox does not continue the open case' do
      let(:fresh_mail) do
        create_inbound_email_from_mail(from: 'email@gmail.com', to: 'imap@gmail.com', subject: 'Reembolso')
      end

      it 'starts a new conversation even with one open' do
        create(:conversation, account: account, inbox: channel.inbox, contact: contact, status: :open)

        expect { class_instance.process(fresh_mail.mail, channel) }.to change(Conversation, :count).by(1)
      end
    end
  end
end
