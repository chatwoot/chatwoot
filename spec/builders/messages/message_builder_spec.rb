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

    context 'when is_voice_message is true' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/sample.ogg', 'audio/ogg')],
                                           is_voice_message: true
                                         })
      end

      it 'sets is_voice_message in attachment meta' do
        message = message_builder
        expect(message.attachments.first.meta).to include('is_voice_message' => true)
      end
    end

    context 'when is_voice_message is not provided' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')]
                                         })
      end

      it 'does not set is_voice_message in attachment meta' do
        message = message_builder
        expect(message.attachments.first.meta).not_to include('is_voice_message')
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

      context 'when custom email content is provided' do
        before do
          account.enable_features('quoted_email_reply')
        end

        it 'creates message with custom HTML email content' do
          params = ActionController::Parameters.new({
                                                      content: 'Regular message content',
                                                      email_html_content: '<p>Custom <strong>HTML</strong> content</p>'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content', 'full')).to eq '<p>Custom <strong>HTML</strong> content</p>'
          expect(message.content_attributes.dig('email', 'html_content', 'reply')).to eq '<p>Custom <strong>HTML</strong> content</p>'
          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Regular message content'
          expect(message.content_attributes.dig('email', 'text_content', 'reply')).to eq 'Regular message content'
        end

        it 'does not process custom email content for private messages' do
          params = ActionController::Parameters.new({
                                                      content: 'Regular message content',
                                                      email_html_content: '<p>Custom HTML content</p>',
                                                      private: true
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content')).to be_nil
          expect(message.content_attributes.dig('email', 'text_content')).to be_nil
        end

        it 'falls back to default behavior when no custom email content is provided' do
          params = ActionController::Parameters.new({
                                                      content: 'Regular **markdown** content'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content', 'full')).to include('<strong>markdown</strong>')
          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Regular **markdown** content'
        end
      end

      context 'when liquid templates are present in email content' do
        let(:contact) { create(:contact, name: 'John', email: 'john@example.com') }
        let(:conversation) { create(:conversation, inbox: channel_email.inbox, account: account, contact: contact) }

        it 'processes liquid variables in email content' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}, your email is {{contact.email}}'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content', 'full')).to include('Hello John')
          expect(message.content_attributes.dig('email', 'html_content', 'full')).to include('john@example.com')
          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hello John, your email is john@example.com'
        end

        it 'does not process liquid in code blocks' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}, use this code: `{{contact.email}}`'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hello John, use this code: `{{contact.email}}`'
        end

        it 'handles broken liquid syntax gracefully' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}  {{invalid}}'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hello {{contact.name}  {{invalid}}'
        end

        it 'does not process liquid for incoming messages' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}',
                                                      message_type: 'incoming'
                                                    })

          api_channel = create(:channel_api, account: account)
          api_conversation = create(:conversation, inbox: api_channel.inbox, account: account, contact: contact)

          message = described_class.new(user, api_conversation, params).perform

          expect(message.content).to eq 'Hello {{contact.name}}'
        end

        it 'does not process liquid for private messages' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}',
                                                      private: true
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content')).to be_nil
          expect(message.content_attributes.dig('email', 'text_content')).to be_nil
        end
      end
    end
  end
end
