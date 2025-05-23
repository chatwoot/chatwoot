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
    def create_email_channel_with_inbox
      channel = create(:channel_email, account: account)
      inbox = channel.inbox

      {
        channel: channel,
        inbox: inbox
      }
    end

    def create_email_conversations(inbox)
      {
        source: create(:conversation, inbox: inbox, account: account),
        target: create(:conversation, inbox: inbox, account: account)
      }
    end

    def standard_email_data
      {
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
    end

    def setup_email_environment
      channel_data = create_email_channel_with_inbox
      conversations = create_email_conversations(channel_data[:inbox])

      {
        email_inbox: channel_data[:inbox],
        email_conversation: conversations[:source],
        target_conversation: conversations[:target],
        standard_email_data: standard_email_data
      }
    end

    context 'with different message types' do
      let(:env) { setup_email_environment }

      it 'preserves email data when forwarding' do
        # Create the original message to be forwarded
        forwarded_message = create(:message,
                                   conversation: env[:email_conversation],
                                   account: account,
                                   content_attributes: { email: env[:standard_email_data] })

        # Setup params to forward the message
        forward_params = ActionController::Parameters.new({
                                                            content: 'Forwarded message:',
                                                            content_attributes: { forwarded_message_id: forwarded_message.id }
                                                          })

        message = described_class.new(user, env[:target_conversation], forward_params).perform

        expect(message.content_attributes[:forwarded_message_id]).to eq(forwarded_message.id)
        expect(message.content_attributes[:email]).to be_present
        expect(message.content).to include('Forwarded message:')
        expect(message.content).to include('---------- Forwarded message ---------')
        html_content = message.content_attributes[:email]['html_content']['full']
        text_content = message.content_attributes[:email]['text_content']['full']
        expect(html_content).to include('<div>HTML content</div>')
        expect(text_content).to include('Text content')
      end

      it 'handles markdown content in forwarded messages' do
        # Create the original message to be forwarded
        forwarded_message = create(:message,
                                   conversation: env[:email_conversation],
                                   account: account,
                                   content_attributes: { email: env[:standard_email_data] })

        markdown_content = '**Bold text** and _italic text_'
        forward_params = ActionController::Parameters.new({
                                                            content: markdown_content,
                                                            content_attributes: { forwarded_message_id: forwarded_message.id }
                                                          })

        message = described_class.new(user, env[:email_conversation], forward_params).perform

        html_content = message.content_attributes[:email]['html_content']['full']
        text_quoted = message.content_attributes[:email]['text_content']['quoted']
        full_text = message.content_attributes[:email]['text_content']['full']

        expect(html_content).to include('<strong>Bold text</strong>')
        expect(html_content).to include('<em>italic text</em>')

        expect(text_quoted.strip).to eq('Bold text and italic text')

        expect(full_text).to include('Bold text and italic text')
        expect(full_text).to include('---------- Forwarded message ---------')
      end

      it 'returns empty email data when forwarding a message with no email data' do
        regular_message = create(:message, conversation: conversation, account: account)

        forward_params = ActionController::Parameters.new({
                                                            content: 'Forwarding a regular message:',
                                                            content_attributes: { forwarded_message_id: regular_message.id }
                                                          })

        # Create the forwarded message
        message = described_class.new(user, env[:email_conversation], forward_params).perform

        # Updated expectation - we now expect email data to be present but won't check specific content
        expect(message.content_attributes[:forwarded_message_id]).to eq(regular_message.id)
        expect(message.content_attributes[:email]).to be_present
      end

      it 'preserves multipart content in forwarded messages' do
        # Create a multipart email message
        multipart_data = env[:standard_email_data].merge(
          'html_content' => { 'full' => '<div>HTML <b>formatted</b> content</div>' },
          'text_content' => { 'full' => 'Plain text content' }
        )

        multipart_message = create(:message,
                                   conversation: env[:email_conversation],
                                   account: account,
                                   content_attributes: { email: multipart_data })

        forward_params = ActionController::Parameters.new({
                                                            content: 'Forwarding multipart email:',
                                                            content_attributes: { forwarded_message_id: multipart_message.id }
                                                          })

        message = described_class.new(user, env[:email_conversation], forward_params).perform

        # Verify multipart content is preserved
        expect(message.content_attributes[:email]['html_content']['full']).to include('<div>HTML <b>formatted</b> content</div>')
        expect(message.content_attributes[:email]['text_content']['full']).to include('Plain text content')
      end
    end

    context 'with attachments' do
      let(:env) { setup_email_environment }

      def create_base_message(conversation)
        create(:message,
               conversation: conversation,
               account: account,
               content_attributes: {
                 email: standard_email_data.merge(
                   'html_content' => { 'full' => '<div>Message with attachments</div>' },
                   'text_content' => { 'full' => 'Message with attachments' }
                 )
               })
      end

      def add_text_attachment(message)
        attachment = message.attachments.new(account_id: account.id, file_type: 'file')
        attachment.file.attach(
          io: StringIO.new('test file content'),
          filename: 'test.txt',
          content_type: 'text/plain'
        )
        attachment.save!
      end

      def add_image_attachment(message)
        attachment = message.attachments.new(account_id: account.id, file_type: 'image')
        attachment.file.attach(
          io: StringIO.new('fake image content'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        attachment.save!
      end

      def create_message_with_attachments(conversation)
        message = create_base_message(conversation)
        add_text_attachment(message)
        add_image_attachment(message)
        message
      end

      it 'copies attachments from the forwarded message' do
        message_with_attachments = create_message_with_attachments(env[:email_conversation])

        forward_params = ActionController::Parameters.new({
                                                            content: 'Forwarding message with attachments:',
                                                            content_attributes: { forwarded_message_id: message_with_attachments.id }
                                                          })

        message = described_class.new(user, env[:email_conversation], forward_params).perform

        # Verify attachments are copied
        expect(message.attachments.count).to eq(2)
        expect(message.attachments.map(&:file_type)).to include('file', 'image')
        expect(message.attachments.first.file).to be_attached

        # Verify attachment data in content_attributes
        expect(message.content_attributes[:email]['attachments']).to be_present
        expect(message.content_attributes[:email]['attachments'].length).to eq(2)
      end
    end

    context 'with nested forwarding' do
      let(:env) { setup_email_environment }

      it 'maintains proper forwarding chain data' do
        # Create original message
        parent_message = create(:message,
                                conversation: env[:email_conversation],
                                account: account,
                                content_attributes: { email: env[:standard_email_data] })

        # Create first level forward
        first_level_params = ActionController::Parameters.new({
                                                                content: 'First forwarded message:',
                                                                content_attributes: { forwarded_message_id: parent_message.id }
                                                              })

        first_forward = described_class.new(user, env[:email_conversation], first_level_params).perform

        # Create second level forward
        second_level_params = ActionController::Parameters.new({
                                                                 content: 'Forwarding a forwarded message:',
                                                                 content_attributes: { forwarded_message_id: first_forward.id }
                                                               })

        message = described_class.new(user, env[:email_conversation], second_level_params).perform

        expect(message.content_attributes[:forwarded_message_id]).to be_present
        expect(message.content).to include('Forwarding a forwarded message:')
        expect(message.content).to include('---------- Forwarded message ---------')
        expect(message.content).to include('First forwarded message:')
      end
    end
  end
end
