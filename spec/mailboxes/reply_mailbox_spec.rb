require 'rails_helper'

RSpec.describe ReplyMailbox do
  include ActionMailbox::TestHelper

  describe 'add mail as reply in a conversation' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
    let(:reply_mail) { create_inbound_email_from_fixture('reply.eml') }
    let(:reply_to_mail) { create_inbound_email_from_fixture('reply_to.eml') }
    let(:mail_with_quote) { create_inbound_email_from_fixture('mail_with_quote.eml') }
    let(:conversation) { create(:conversation, assignee: agent, inbox: create(:inbox, account: account, greeting_enabled: false), account: account) }
    let(:described_subject) { described_class.receive reply_mail }
    let(:serialized_attributes) do
      %w[bcc cc content_type date from headers html_content in_reply_to message_id multipart number_of_attachments references subject text_content
         to auto_reply]
    end

    context 'with reply uuid present' do
      before do
        # this UUID is hardcoded in the reply.eml, that's why we are updating this
        conversation.uuid = '6bdc3f4d-0bec-4515-a284-5d916fdde489'
        conversation.save!

        described_subject
      end

      it 'add the mail content as new message on the conversation' do
        expect(conversation.messages.last.content).to eq("Let's talk about these images:")
      end

      it 'add the attachments' do
        expect(conversation.messages.last.attachments.count).to eq(2)
      end

      it 'have proper content_attributes with details of email' do
        expect(conversation.messages.last.content_attributes[:email].keys).to eq(serialized_attributes)
      end

      it 'set proper content_type' do
        expect(conversation.messages.last.content_type).to eq('incoming_email')
      end
    end

    context 'with in reply to email' do
      let(:reply_mail_without_uuid) { create_inbound_email_from_fixture('reply_mail_without_uuid.eml') }
      let(:described_subject) { described_class.receive reply_mail_without_uuid }
      let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
      let(:conversation_1) do
        create(
          :conversation,
          assignee: agent,
          inbox: email_channel.inbox,
          account: account,
          additional_attributes: { mail_subject: "Discussion: Let's debate these attachments" }
        )
      end

      before do
        conversation_1.update!(uuid: '6bdc3f4d-0bec-4515-a284-5d916fdde489')
        reply_mail_without_uuid.mail['In-Reply-To'] = '<conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489/messages/123@test.com>'
      end

      it 'find channel with in-reply-to mail' do
        described_subject
        expect(conversation_1.messages.last.content).to include("Let's talk about these images:")
      end
    end

    context 'with inline attachments' do
      let(:mail_with_inline_images) { create_inbound_email_from_fixture('mail_with_inline_images.eml') }
      let(:described_subject) { described_class.receive mail_with_inline_images }

      before do
        conversation.uuid = '6bdc3f4d-0bed-4515-a284-5d916fdde489'
        conversation.save!

        described_subject
      end

      it 'mail content contains img source' do
        expect(conversation.messages.last.content).to include('HTML content and inline images')
      end

      it 'will not add the attachments' do
        expect(conversation.messages.last.attachments.count).to eq(0)

        html_full_content = conversation.messages.last.content_attributes[:email][:html_content][:full]
        expect(html_full_content).to include('img')
        expect(html_full_content).not_to include('cid:ii_lm7fuura0')
        expect(html_full_content).not_to include('cid:ii_lm7fuuvm1')
        expect(html_full_content).not_to include('cid:ii_lm7fuuwn2')
      end
    end

    context 'with inline attachments and plain text' do
      let(:mail_with_plain_text_and_inline_image) { create_inbound_email_from_fixture('mail_with_plain_text_and_inline_image.eml') }
      let(:described_subject) { described_class.receive mail_with_plain_text_and_inline_image }

      before do
        conversation.uuid = '6bdc3f4d-0bed-4515-a284-5d916fdde489'
        conversation.save!

        described_subject
      end

      it 'will not add the attachments' do
        described_class.receive mail_with_plain_text_and_inline_image
        text_full_content = conversation.messages.last.content_attributes[:email][:text_content][:full]

        expect(text_full_content).to include('img')
        expect(text_full_content).not_to include('[image: poster (8).jpg]')
        expect(text_full_content).not_to include('[image: poster (7).jpg]')
        expect(text_full_content).not_to include('[image: poster (1).jpg]')
        expect(conversation.messages.last.content).to include("Let's add no HTML content here, just plain text and images")
        expect(conversation.messages.last.attachments.count).to eq(0)
      end
    end

    context 'with inline attachments and html_part' do
      let(:mail_with_html_part_no_html_content) { create_inbound_email_from_fixture('mail_with_html_part_no_html_content.eml') }
      let(:described_subject) { described_class.receive mail_with_html_part_no_html_content }

      before do
        conversation.uuid = '6bdc3f4d-0bed-4515-a284-5d916fdde489'
        conversation.save!

        described_subject
      end

      it 'mail content will create message' do
        expect(conversation.messages.last.content).to include('This is test message.')
      end

      it 'html_content is empty' do
        expect(conversation.messages.last.attachments.count).to eq(0)

        html_full_content = conversation.messages.last.content_attributes[:email][:html_content][:full]
        expect(html_full_content).to be_nil
      end
    end

    context 'with reply_to email address present' do
      let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
      let(:conversation_1) do
        create(
          :conversation,
          assignee: agent,
          inbox: email_channel.inbox,
          account: account,
          additional_attributes: { mail_subject: "Discussion: Let's debate these attachments" }
        )
      end

      before do
        conversation_1.update!(uuid: '6bdc3f4d-0bec-4515-a284-5d916fdde489')
      end

      it 'prefer reply-to over from address' do
        described_class.receive reply_to_mail
        expect(conversation_1.messages.last.content).to eq("Let's talk about these images:")

        email = conversation_1.messages.last.content_attributes['email']
        expect(reply_to_mail.mail['Reply-To'].value).to include(email['from'][0])
      end
    end

    context 'without email to address' do
      let(:forwarder_email) { create_inbound_email_from_fixture('forwarder_email.eml') }
      let(:in_reply_to_email) { create_inbound_email_from_fixture('in_reply_to.eml') }
      let(:described_subject) { described_class.receive forwarder_email }
      let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
      let(:conversation_1) do
        create(
          :conversation,
          assignee: agent,
          inbox: email_channel.inbox,
          account: account,
          additional_attributes: { mail_subject: "Discussion: Let's debate these attachments" }
        )
      end

      before do
        conversation_1.update!(uuid: '6bdc3f4d-0bec-4515-a284-5d916fdde489')
      end

      it 'find channel with forwarded to mail' do
        described_subject
        expect(conversation_1.messages.last.content).to eq("Let's talk about these images:")
      end

      it 'find channel with in message source id stated in in_reply_to' do
        conversation_1.messages.new(source_id: '0CB459E0-0336-41DA-BC88-E6E28C697DDB@chatwoot.com', account_id: account.id, message_type: 'incoming',
                                    inbox_id: email_channel.inbox.id).save!
        described_class.receive in_reply_to_email
        expect(conversation_1.messages.last.content).to eq("Let's talk about these images:")
      end
    end

    context 'with quotes in email' do
      let(:described_subject) { described_class.receive mail_with_quote }

      before do
        # this UUID is hardcoded in the reply.eml, that's why we are updating this
        conversation.uuid = '6bdc3f4d-0bec-4515-a284-5d916fdde489'
        conversation.save!
      end

      it 'add the mail content as new message on the conversation' do
        described_subject
        current_message = conversation.messages.last
        expect(current_message.content).to eq(
          <<~BODY.chomp
            Yes, I am providing you step how to reproduce this issue

            On Thu, Aug 19, 2021 at 2:07 PM Tejaswini from Email sender test < tejaswini@chatwoot.com> wrote:

            > Any update on this?
            >
            >

            --
            * Sony Mathew*
            Software developer
            *Mob:9999999999
          BODY
        )
      end

      it 'add the mail content as new message on the conversation with broken html' do
        described_subject
        current_message = conversation.messages.last
        expect(current_message.reload.content_attributes[:email][:text_content][:reply]).to eq(
          <<~BODY.chomp
            Yes, I am providing you step how to reproduce this issue

            On Thu, Aug 19, 2021 at 2:07 PM Tejaswini from Email sender test < tejaswini@chatwoot.com> wrote:

            > Any update on this?
            >
            >

            --
            * Sony Mathew*
            Software developer
            *Mob:9999999999
          BODY
        )
      end
    end

    context 'with references header' do
      let(:reply_mail_with_references) { create_inbound_email_from_fixture('reply_mail_without_uuid.eml') }
      let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
      let(:conversation_1) do
        create(
          :conversation,
          assignee: agent,
          inbox: email_channel.inbox,
          account: account,
          additional_attributes: { mail_subject: "Discussion: Let's debate these attachments" }
        )
      end

      before do
        conversation_1.update!(uuid: '6bdc3f4d-0bec-4515-a284-5d916fdde489')
      end

      context 'with message-specific pattern in references' do
        before do
          reply_mail_with_references.mail['References'] = '<conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489/messages/123@test.com>'
        end

        it 'finds conversation from references header with message pattern' do
          described_class.receive reply_mail_with_references
          expect(conversation_1.messages.last.content).to include("Let's talk about these images:")
        end
      end

      context 'with conversation fallback pattern in references' do
        before do
          reply_mail_with_references.mail['References'] = "<account/#{account.id}/conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489@test.com>"
        end

        it 'finds conversation from references header with fallback pattern' do
          described_class.receive reply_mail_with_references
          expect(conversation_1.messages.last.content).to include("Let's talk about these images:")
        end
      end

      context 'with multiple references including conversation pattern' do
        before do
          reply_mail_with_references.mail['References'] = [
            '<some-random-message-id@gmail.com>',
            "<account/#{account.id}/conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489@test.com>",
            '<another-random-message-id@outlook.com>'
          ].join("\r\n ")
        end

        it 'finds conversation from any reference in the chain' do
          described_class.receive reply_mail_with_references
          expect(conversation_1.messages.last.content).to include("Let's talk about these images:")
        end
      end

      context 'with message source_id in references' do
        before do
          conversation_1.messages.create!(
            source_id: 'original-message-id@test.com',
            account_id: account.id,
            message_type: 'outgoing',
            inbox_id: email_channel.inbox.id,
            content: 'Original message'
          )
          reply_mail_with_references.mail['References'] = '<original-message-id@test.com>'
        end

        it 'finds conversation from message source_id in references' do
          described_class.receive reply_mail_with_references
          expect(conversation_1.messages.last.content).to include("Let's talk about these images:")
        end
      end

      context 'with conversation from different channel in references' do
        let(:other_email_channel) { create(:channel_email, email: 'other@example.com', account: account) }
        let(:other_conversation) do
          create(
            :conversation,
            assignee: agent,
            inbox: other_email_channel.inbox,
            account: account
          )
        end

        before do
          other_conversation.update!(uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
          reply_mail_with_references.mail['References'] = '<conversation/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/messages/456@test.com>'
        end

        it 'does not use conversation from different channel' do
          described_class.receive reply_mail_with_references
          expect(other_conversation.messages.count).to eq(0)
        end
      end
    end
  end

  describe 'when a chatwoot notification email is received' do
    let(:account) { create(:account) }
    let!(:channel_email) { create(:channel_email, email: 'sojan@chatwoot.com', account: account) }
    let(:notification_mail) { create_inbound_email_from_fixture('notification.eml') }
    let(:described_subject) { described_class.receive notification_mail }
    let(:conversation) { Conversation.where(inbox_id: channel_email.inbox).last }

    it 'shouldnt create a conversation in the channel' do
      described_subject
      expect(conversation.present?).to be(false)
    end
  end

  describe 'when bounced email with out a sender is recieved' do
    let(:account) { create(:account) }
    let(:bounced_email) { create_inbound_email_from_fixture('bounced_with_no_from.eml') }
    let(:described_subject) { described_class.receive bounced_email }

    it 'shouldnt throw an error' do
      create(:channel_email, email: 'support@example.com', account: account)
      expect { described_subject }.not_to raise_error
    end
  end

  describe 'when an account is suspended' do
    let(:account) { create(:account, status: :suspended) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
    let!(:channel_email) { create(:channel_email, account: account) }
    let(:support_mail) { create_inbound_email_from_fixture('support.eml') }
    let(:described_subject) { described_class.receive support_mail }
    let(:conversation) { Conversation.where(inbox_id: channel_email.inbox).last }

    before do
      # this email is hardcoded in the support.eml, that's why we are updating this
      channel_email.email = 'care@example.com'
      channel_email.save!
    end

    it 'shouldnt create a conversation in the channel' do
      described_subject
      expect(conversation.present?).to be(false)
    end
  end

  describe 'add mail as a new ticket in the email inbox' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
    let!(:channel_email) { create(:channel_email, account: account) }
    let(:support_mail) { create_inbound_email_from_fixture('support.eml') }
    let(:support_in_reply_to_mail) { create_inbound_email_from_fixture('support_in_reply_to.eml') }
    let(:described_subject) { described_class.receive support_mail }
    let(:serialized_attributes) do
      %w[bcc cc content_type date from headers html_content in_reply_to message_id multipart number_of_attachments references subject
         text_content to auto_reply]
    end
    let(:conversation) { Conversation.where(inbox_id: channel_email.inbox).last }

    before do
      # this email is hardcoded in the support.eml, that's why we are updating this
      channel_email.email = 'care@example.com'
      channel_email.save!
    end

    describe 'covers email address format' do
      before do
        described_class.receive support_in_reply_to_mail
      end

      it 'creates contact with proper email address' do
        expect(support_in_reply_to_mail.mail['reply_to'].try(:value)).to eq('Sony Mathew <sony@chatwoot.com>')
        expect(conversation.contact.email).to eq('sony@chatwoot.com')
      end
    end

    describe 'covers basic ticket creation' do
      before do
        described_subject
      end

      it 'create the conversation in the inbox of the email channel' do
        expect(conversation.inbox.id).to eq(channel_email.inbox.id)
        expect(conversation.additional_attributes['source']).to eq('email')
        expect(conversation.contact.email).to eq(support_mail.mail.from.first)
      end

      it 'create a new contact as the sender of the email' do
        email_sender = Mail::Address.new(support_mail.mail[:from].value).name
        expect(conversation.messages.last.sender.email).to eq(support_mail.mail.from.first)
        expect(conversation.contact.name).to eq(email_sender)
      end

      it 'add the mail content as new message on the conversation' do
        expect(conversation.messages.last.content).to eq("Let's talk about these images:")
      end

      it 'add the attachments' do
        expect(conversation.messages.last.attachments.count).to eq(2)
      end

      it 'have proper content_attributes with details of email' do
        expect(conversation.messages.last.content_attributes[:email].keys).to eq(serialized_attributes)
      end

      it 'set proper content_type' do
        expect(conversation.messages.last.content_type).to eq('incoming_email')
      end
    end

    describe 'email with references header' do
      let(:mail_with_references) { create_inbound_email_from_fixture('mail_with_references.eml') }
      let(:described_subject) { described_class.receive mail_with_references }

      before do
        # reuse the existing channel_email that's already set to 'care@example.com'
        described_subject
      end

      it 'includes references in the message content_attributes' do
        message = conversation.messages.last
        email_attributes = message.content_attributes['email']

        expect(email_attributes['references']).to be_present
        expect(email_attributes['references']).to eq(['4e6e35f5a38b4_479f13bb90078178@small-app-01.mail', 'test-reference-id'])
      end

      it 'includes references in serialized email attributes' do
        message = conversation.messages.last
        expect(message.content_attributes['email'].keys).to include('references')
      end
    end

    describe 'Sender without name' do
      let(:support_mail_without_sender_name) { create_inbound_email_from_fixture('support_without_sender_name.eml') }
      let(:described_subject) { described_class.receive support_mail_without_sender_name }

      it 'create a new contact with the email' do
        described_subject
        email_sender = support_mail_without_sender_name.mail.from.first.split('@').first
        expect(conversation.messages.last.sender.email).to eq(support_mail.mail.from.first)
        expect(conversation.contact.name).to eq(email_sender)
      end
    end

    describe 'Sender with upcase mail address' do
      let(:support_mail_without_sender_name) { create_inbound_email_from_fixture('support_without_sender_name.eml') }
      let(:described_subject) { described_class.receive support_mail_without_sender_name }

      it 'create a new inbox with the email case insensitive' do
        described_subject
        expect(conversation.inbox.id).to eq(channel_email.inbox.id)
      end
    end

    describe 'handle inbox contacts' do
      let!(:contact) { create(:contact, account: account, email: support_mail.mail.from.first) }
      let!(:contact_inbox) { create(:contact_inbox, inbox: channel_email.inbox, contact: contact) }

      it 'does not create new contact if that contact exists in the inbox' do
        expect do
          described_subject
        end
          .to(not_change { Contact.count }
            .and(not_change { ContactInbox.count }))

        expect(conversation.messages.last.sender.id).to eq(contact.id)
        expect(conversation.contact_inbox).to eq(contact_inbox)
      end

      context 'with uppercase reply-to' do
        let(:support_mail) { create_inbound_email_from_fixture('support_uppercase.eml') }
        let!(:contact) { create(:contact, account: account, email: support_mail.mail.from.first) }
        let!(:contact_inbox) { create(:contact_inbox, inbox: channel_email.inbox, contact: contact) }

        it 'does not create new contact if that contact exists in the inbox' do
          expect do
            described_subject
          end
            .to(not_change { Contact.count }
              .and(not_change { ContactInbox.count }))

          expect(conversation.messages.last.sender.id).to eq(contact.id)
          expect(conversation.contact_inbox).to eq(contact_inbox)
        end
      end
    end

    describe 'group email sender' do
      let(:group_sender_support_mail) { create_inbound_email_from_fixture('group_sender_support.eml') }
      let(:described_subject) { described_class.receive group_sender_support_mail }

      before do
        # this email is hardcoded eml fixture file that's why we are updating this
        channel_email.email = 'support@chatwoot.com'
        channel_email.save!
      end

      it 'create new contact with original sender' do
        described_subject
        email_sender = Mail::Address.new(group_sender_support_mail.mail[:from].value).name

        expect(conversation.contact.email).to eq(group_sender_support_mail.mail['X-Original-Sender'].value)
        expect(conversation.contact.name).to eq(email_sender)
      end
    end

    describe 'when mail has in reply to email' do
      let(:reply_mail_without_uuid) { create_inbound_email_from_fixture('reply_mail_without_uuid.eml') }
      let(:described_subject) { described_class.receive reply_mail_without_uuid }
      let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }

      before do
        email_channel
        reply_mail_without_uuid.mail['In-Reply-To'] = 'conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489/messages/123'
      end

      it 'create channel with reply to mail' do
        described_subject
        conversation_1 = Conversation.last

        expect(conversation_1.messages.last.content).to eq("Let's talk about these images:")
        expect(conversation_1.additional_attributes['in_reply_to']).to eq('conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489/messages/123')
      end

      it 'append message to email conversation with same in reply to' do
        described_subject
        conversation_1 = Conversation.last

        expect(conversation_1.messages.last.content).to eq("Let's talk about these images:")
        expect(conversation_1.additional_attributes['in_reply_to']).to eq('conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489/messages/123')
        expect(conversation_1.messages.count).to eq(1)

        reply_mail_without_uuid.mail['In-Reply-To'] = 'conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489/messages/123'
        reply_mail_without_uuid.mail['Message-Id'] = '0CB459E0-0336-41DA-BC88-E6E28C697SFC@chatwoot.com'

        described_class.receive reply_mail_without_uuid

        expect(conversation_1.messages.last.content).to eq("Let's talk about these images:")
        expect(conversation_1.additional_attributes['in_reply_to']).to eq('conversation/6bdc3f4d-0bec-4515-a284-5d916fdde489/messages/123')
        expect(conversation_1.messages.count).to eq(2)
      end
    end

    describe 'Sender with reply_to email address' do
      let(:reply_to_mail) { create_inbound_email_from_fixture('reply_to.eml') }
      let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }

      it 'prefer reply-to over from address' do
        email_channel
        described_class.receive reply_to_mail

        conversation_1 = Conversation.last
        email = conversation_1.messages.last.content_attributes['email']

        expect(reply_to_mail.mail['From'].value).to be_present
        expect(conversation_1.messages.last.content).to eq("Let's talk about these images:")
        expect(reply_to_mail.mail['Reply-To'].value).to include(email['from'][0])
        expect(reply_to_mail.mail['Reply-To'].value).to include(conversation_1.contact.email)
        expect(reply_to_mail.mail['From'].value).not_to include(conversation_1.contact.email)
      end
    end

    describe 'when mail part is not present' do
      let(:support_mail) { create_inbound_email_from_fixture('support_1.eml') }
      let(:only_text) { create_inbound_email_from_fixture('only_text.eml') }
      let(:only_html) { create_inbound_email_from_fixture('only_html.eml') }
      let(:only_attachments) { create_inbound_email_from_fixture('only_attachments.eml') }
      let(:html_and_attachments) { create_inbound_email_from_fixture('html_and_attachments.eml') }
      let(:described_subject) { described_class.receive support_mail }

      it 'Considers raw html mail body' do
        described_subject
        expect(conversation.inbox.id).to eq(channel_email.inbox.id)

        expect(conversation.messages.last.content_attributes['email']['html_content']['reply']).to include(
          <<~BODY.chomp
            Hi,

            We are providing you platform from here you can sell paid posts on your website.

            Chatwoot | CS team | [C](https://d33wubrfki0l68.cloudfront.net/973467c532160fd8b940300a43fa85fa2d060307/dc9a0/static/brand-73f58cdefae282ae74cebfa74c1d7003.svg)

            Skype: live:.cid.something

            []
          BODY
        )
        expect(conversation.messages.last.content_attributes['email']['subject']).to eq('Get Paid to post an article')
      end

      it 'Considers only text body' do
        described_class.receive only_text

        expect(conversation.inbox.id).to eq(channel_email.inbox.id)

        expect(conversation.messages.last.content).to eq('text only mail')
        expect(conversation.messages.last.content_attributes['email']['subject']).to eq('test text only mail')
      end

      it 'Considers only html body' do
        described_class.receive only_html

        expect(conversation.inbox.id).to eq(channel_email.inbox.id)

        expect(conversation.messages.last.content).to eq(
          <<~BODY.chomp
            This is html only mail
          BODY
        )
        expect(conversation.messages.last.content_attributes['email']['subject']).to eq('test html only mail')
      end

      it 'Considers only attachments' do
        described_class.receive only_attachments

        expect(conversation.inbox.id).to eq(channel_email.inbox.id)

        expect(conversation.messages.last.content).to be_nil
        expect(conversation.messages.last.attachments.count).to eq(1)
        expect(conversation.messages.last.content_attributes['email']['subject']).to eq('only attachments')
      end

      it 'Considers html and attachments' do
        described_class.receive html_and_attachments

        expect(conversation.inbox.id).to eq(channel_email.inbox.id)

        expect(conversation.messages.last.content).to eq('This is html and attachments only mail')
        expect(conversation.messages.last.attachments.count).to eq(1)
        expect(conversation.messages.last.content_attributes['email']['subject']).to eq('attachment with html')
      end
    end

    describe 'when BCC processing is disabled for account' do
      before do
        allow(GlobalConfigService).to receive(:load).with('SKIP_INCOMING_BCC_PROCESSING', '').and_return(account.id.to_s)
      end

      it 'does not process BCC-only emails' do
        bcc_mail = create_inbound_email_from_fixture('support.eml')
        bcc_mail.mail['to'] = nil
        bcc_mail.mail['bcc'] = 'care@example.com'

        described_class.receive bcc_mail
        expect(conversation.present?).to be(false)
      end
    end
  end
end
