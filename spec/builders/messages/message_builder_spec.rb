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

  describe 'client_message_id' do
    let(:first_attempt) do
      ActionController::Parameters.new({ content: 'test', client_message_id: '01JD8Z9Q6F7', echo_id: 'attempt-1' })
    end
    let(:retried_attempt) do
      ActionController::Parameters.new({ content: 'test', client_message_id: '01JD8Z9Q6F7', echo_id: 'attempt-2' })
    end

    it 'stores the key and its payload fingerprint on the created message' do
      message = described_class.new(user, conversation, first_attempt).perform

      expect(message.client_message_id).to eq('01JD8Z9Q6F7')
      expect(message.client_message_digest).to be_present
    end

    it 'returns the original message when the client retries a send whose response was lost' do
      original = described_class.new(user, conversation, first_attempt).perform

      replayed = described_class.new(user, conversation, retried_attempt).perform

      expect(replayed.id).to eq(original.id)
      expect(replayed.created_at).to eq(original.reload.created_at)
      expect(conversation.messages.count).to eq(1)
    end

    it 'echoes the correlation id of the retry rather than the original attempt' do
      described_class.new(user, conversation, first_attempt).perform

      replayed = described_class.new(user, conversation, retried_attempt).perform

      expect(replayed.echo_id).to eq('attempt-2')
    end

    it 'does not queue delivery again for a replayed send' do
      described_class.new(user, conversation, first_attempt).perform

      expect { described_class.new(user, conversation, retried_attempt).perform }.not_to have_enqueued_job(SendReplyJob)
    end

    it 'rejects the key when it is reused for different content' do
      described_class.new(user, conversation, first_attempt).perform
      conflicting = ActionController::Parameters.new({ content: 'a different message', client_message_id: '01JD8Z9Q6F7' })

      expect { described_class.new(user, conversation, conflicting).perform }
        .to raise_error(CustomExceptions::ClientMessageIdConflict)
    end

    it 'rejects the key when it is reused to turn a reply into a private note' do
      described_class.new(user, conversation, first_attempt).perform
      conflicting = ActionController::Parameters.new({ content: 'test', private: true, client_message_id: '01JD8Z9Q6F7' })

      expect { described_class.new(user, conversation, conflicting).perform }
        .to raise_error(CustomExceptions::ClientMessageIdConflict)
    end

    it 'replays a retry that a fresh send would now be refused' do
      original = described_class.new(user, conversation, first_attempt).perform

      replayed = with_modified_env CONVERSATION_MESSAGE_PER_MINUTE_LIMIT: '1' do
        described_class.new(user, conversation, retried_attempt).perform
      end

      expect(replayed.id).to eq(original.id)
      expect(conversation.messages.count).to eq(1)
    end

    it 'replays a retry sent after the original message was deleted' do
      original = described_class.new(user, conversation, first_attempt).perform
      original.update!(content: 'This message was deleted', content_type: :text, content_attributes: { deleted: true })

      replayed = described_class.new(user, conversation, retried_attempt).perform

      expect(replayed.id).to eq(original.id)
      expect(conversation.messages.count).to eq(1)
    end

    it 'leaves a transaction the caller opened usable' do
      original = described_class.new(user, conversation, first_attempt).perform

      replayed = nil
      ActiveRecord::Base.transaction do
        replayed = described_class.new(user, conversation, retried_attempt).perform
        conversation.messages.count
      end

      expect(replayed.id).to eq(original.id)
    end

    it 'leaves clients that send no key on the existing behaviour' do
      keyless = ActionController::Parameters.new({ content: 'test' })

      described_class.new(user, conversation, keyless).perform
      described_class.new(user, conversation, keyless).perform

      expect(conversation.messages.count).to eq(2)
    end
  end

  describe 'concurrent sends reusing a client_message_id' do
    # Two callers have to race on separate database connections, which the transaction
    # the rest of the suite shares between the example and the connection cannot provide.
    self.use_transactional_tests = false

    let(:params) { ActionController::Parameters.new({ content: 'test', client_message_id: '01JD8Z9Q6F7' }) }

    # Rows created here are committed, so they have to be removed again. Installation config
    # is seeded once per database and the rest of the suite reads it.
    after do
      tables = ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata installation_configs]
      ActiveRecord::Base.connection.execute("TRUNCATE #{tables.join(', ')} CASCADE")
    end

    it 'creates one message and answers both callers with it' do
      conversation
      user
      barrier = Concurrent::CyclicBarrier.new(2)

      messages = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            barrier.wait
            described_class.new(user, conversation, params.deep_dup).perform
          end
        end
      end.map(&:value)

      expect(conversation.messages.count).to eq(1)
      expect(messages.map(&:id).uniq).to eq([conversation.messages.first.id])
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
