require 'rails_helper'

describe Messages::MessageBuilder do
  subject(:message_builder) { described_class.new(user, conversation, params).perform }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:inbox_member) { create(:inbox_member, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let(:message_for_reply) { create(:message, conversation: conversation) }
  let(:params) do
    ActionController::Parameters.new({
                                       content: 'test'
                                     })
  end

  describe '#perform' do
    it 'creates a message' do
      message = message_builder
      expect(message.content).to eq params[:content]
    end
  end

  describe '#content_attributes' do
    context 'when content_attributes is a JSON string' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: "{\"in_reply_to\":#{message_for_reply.id}}"
                                         })
      end

      it 'parses content_attributes from JSON string' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content_attributes).to include(in_reply_to: message_for_reply.id)
      end
    end

    context 'when content_attributes is a hash' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: { in_reply_to: message_for_reply.id }
                                         })
      end

      it 'uses content_attributes as provided' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content_attributes).to include(in_reply_to: message_for_reply.id)
      end
    end

    context 'when content_attributes is absent' do
      let(:params) do
        ActionController::Parameters.new({ content: 'test' })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end

    context 'when content_attributes is nil' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: nil
                                         })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end

    context 'when content_attributes is an invalid JSON string' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: 'invalid_json'
                                         })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end
  end

  describe '#perform when message_type is incoming' do
    context 'when channel is not api' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           message_type: 'incoming'
                                         })
      end

      it 'creates throws error when channel is not api' do
        expect { message_builder }.to raise_error 'Incoming messages are only allowed in Api inboxes'
      end
    end

    context 'when channel is api' do
      let(:channel_api) { create(:channel_api, account: account) }
      let(:conversation) { create(:conversation, inbox: channel_api.inbox, account: account) }
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           message_type: 'incoming'
                                         })
      end

      it 'creates message when channel is api' do
        message = message_builder
        expect(message.message_type).to eq params[:message_type]
      end
    end

    context 'when attachment messages' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')]
                                         })
      end

      it 'creates message with attachments' do
        message = message_builder
        expect(message.attachments.first.file_type).to eq 'image'
      end

      context 'when DIRECT_UPLOAD_ENABLED' do
        let(:params) do
          ActionController::Parameters.new({
                                             content: 'test',
                                             attachments: [get_blob_for('spec/assets/avatar.png', 'image/png').signed_id]
                                           })
        end

        it 'creates message with attachments' do
          message = message_builder
          expect(message.attachments.first.file_type).to eq 'image'
        end
      end
    end

    context 'when email channel messages' do
      let!(:channel_email) { create(:channel_email, account: account) }
      let(:inbox_member) { create(:inbox_member, inbox: channel_email.inbox) }
      let(:conversation) { create(:conversation, inbox: channel_email.inbox, account: account) }
      let(:params) do
        ActionController::Parameters.new({ cc_emails: 'test_cc_mail@test.com', bcc_emails: 'test_bcc_mail@test.com' })
      end

      it 'creates message with content_attributes for cc and bcc email addresses' do
        message = message_builder

        expect(message.content_attributes[:cc_emails]).to eq [params[:cc_emails]]
        expect(message.content_attributes[:bcc_emails]).to eq [params[:bcc_emails]]
      end

      it 'does not create message with wrong cc and bcc email addresses' do
        params = ActionController::Parameters.new({ cc_emails: 'test.com', bcc_emails: 'test_bcc.com' })
        expect { described_class.new(user, conversation, params).perform }.to raise_error 'Invalid email address'
      end

      it 'strips off whitespace before saving cc_emails and bcc_emails' do
        cc_emails = ' test1@test.com , test2@test.com, test3@test.com'
        bcc_emails = 'test1@test.com,test2@test.com, test3@test.com '
        params = ActionController::Parameters.new({ cc_emails: cc_emails, bcc_emails: bcc_emails })

        message = described_class.new(user, conversation, params).perform

        expect(message.content_attributes[:cc_emails]).to eq ['test1@test.com', 'test2@test.com', 'test3@test.com']
        expect(message.content_attributes[:bcc_emails]).to eq ['test1@test.com', 'test2@test.com', 'test3@test.com']
      end
    end
  end

  describe '#perform with forwarded messages' do
    let(:email_channel) { create(:channel_email, account: account) }
    let(:email_inbox) { email_channel.inbox }
    let(:email_conversation) { create(:conversation, inbox: email_inbox, account: account) }

    # Create a message with email data to be forwarded
    let(:forwarded_message) do
      create(:message, conversation: email_conversation, account: account,
                       content_attributes: {
                         email: {
                           'from' => ['sender@example.com'],
                           'to' => ['recipient@example.com'],
                           'subject' => 'Test Subject',
                           'date' => '2025-04-29T14:29:07+05:30',
                           'html_content' => {
                             'full' => '<div>HTML content</div>',
                             'quoted' => 'HTML content',
                             'reply' => 'HTML content'
                           },
                           'text_content' => {
                             'full' => 'Text content',
                             'quoted' => 'Text content',
                             'reply' => 'Text content'
                           }
                         }
                       })
    end

    context 'when forwarding a message from a non-email inbox' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'Forwarded message:',
                                           content_attributes: { forwarded_message_id: forwarded_message.id }
                                         })
      end

      it 'includes the forwarded message ID in content_attributes' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content_attributes[:forwarded_message_id]).to eq(forwarded_message.id)
      end

      it 'updates the content with the forwarded message text' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content).to include('Forwarded message:')
        expect(message.content).to include('---------- Forwarded message ---------')
      end
    end

    context 'when forwarding a message from an email inbox' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'Forwarded message:',
                                           content_attributes: { forwarded_message_id: forwarded_message.id }
                                         })
      end

      let(:email_conversation_target) { create(:conversation, inbox: email_inbox, account: account) }

      it 'includes the forwarded email data in content_attributes' do
        message = described_class.new(user, email_conversation_target, params).perform

        expect(message.content_attributes[:forwarded_message_id]).to eq(forwarded_message.id)
        expect(message.content_attributes[:email]).to be_present
        expect(message.content_attributes[:email]['html_content']).to be_present
        expect(message.content_attributes[:email]['text_content']).to be_present
      end

      it 'preserves the HTML content in the forwarded email' do
        message = described_class.new(user, email_conversation_target, params).perform

        html_content = message.content_attributes[:email]['html_content']['full']
        expect(html_content).to include('<div>HTML content</div>')
      end

      it 'preserves the text content in the forwarded email' do
        message = described_class.new(user, email_conversation_target, params).perform

        text_content = message.content_attributes[:email]['text_content']['full']
        expect(text_content).to include('Text content')
      end
    end

    context 'when forwarding a message with markdown content' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: '**Bold text** and _italic text_',
                                           content_attributes: { forwarded_message_id: forwarded_message.id }
                                         })
      end

      it 'converts markdown to HTML in the HTML content' do
        message = described_class.new(user, email_conversation, params).perform

        html_content = message.content_attributes[:email]['html_content']['full']
        expect(html_content).to include('<b>Bold text</b>')
        expect(html_content).to include('<i>italic text</i>')
      end

      it 'preserves markdown in the text content' do
        message = described_class.new(user, email_conversation, params).perform

        text_content = message.content_attributes[:email]['text_content']['full']
        expect(text_content).to include('**Bold text**')
        expect(text_content).to include('_italic text_')
      end
    end

    context 'when forwarding a message with no email data' do
      let(:regular_message) { create(:message, conversation: conversation, account: account) }

      let(:params) do
        ActionController::Parameters.new({
                                           content: 'Forwarding a regular message:',
                                           content_attributes: { forwarded_message_id: regular_message.id }
                                         })
      end

      it 'includes the forwarded message ID and empty email data' do
        message = described_class.new(user, email_conversation, params).perform

        expect(message.content_attributes[:forwarded_message_id]).to eq(regular_message.id)
        expect(message.content_attributes[:email]).to eq({})
      end
    end

    context 'with multipart email content' do
      let(:multipart_message) do
        create(:message, conversation: email_conversation, account: account,
                         content_attributes: {
                           email: {
                             'from' => ['sender@example.com'],
                             'to' => ['recipient@example.com'],
                             'subject' => 'Multipart Test',
                             'date' => '2025-04-29T14:29:07+05:30',
                             'html_content' => {
                               'full' => '<div>HTML <b>formatted</b> content</div>'
                             },
                             'text_content' => {
                               'full' => 'Plain text content'
                             }
                           }
                         })
      end

      let(:params) do
        ActionController::Parameters.new({
                                           content: 'Forwarding multipart email:',
                                           content_attributes: { forwarded_message_id: multipart_message.id }
                                         })
      end

      it 'preserves both HTML and text parts in the forwarded email' do
        message = described_class.new(user, email_conversation, params).perform

        expect(message.content_attributes[:email]['html_content']['full']).to include('<div>HTML <b>formatted</b> content</div>')
        expect(message.content_attributes[:email]['text_content']['full']).to include('Plain text content')
      end
    end
  end
end
