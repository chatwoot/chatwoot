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
      %w[bcc cc content_type date from html_content in_reply_to message_id multipart number_of_attachments subject text_content to]
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
  end
end
