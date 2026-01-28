require 'rails_helper'

describe Whatsapp::ConversationSyncService do
  describe '#perform' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
    let(:inbox) { whatsapp_channel.inbox }
    let(:wa_id) { '5511999998888' }

    describe 'message echoes (smb_message_echoes)' do
      context 'when valid text message echo' do
        let(:params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              id: '987654321',
              changes: [{
                field: 'smb_message_echoes',
                value: {
                  messaging_product: 'whatsapp',
                  metadata: {
                    display_phone_number: whatsapp_channel.phone_number.delete('+'),
                    phone_number_id: '123456789'
                  },
                  message_echoes: [{
                    from: whatsapp_channel.phone_number.delete('+'),
                    to: wa_id,
                    id: 'wamid.echo_text_001',
                    timestamp: '1737392700',
                    type: 'text',
                    text: { body: 'Hello! This is a text echo message' }
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end

        it 'creates a contact inbox if not exists' do
          expect { described_class.new(inbox: inbox, params: params).perform }
            .to change(ContactInbox, :count).by(1)
        end

        it 'creates an outgoing message' do
          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_text_001')
          expect(message).to be_present
          expect(message.message_type).to eq('outgoing')
          expect(message.content).to eq('Hello! This is a text echo message')
        end

        it 'sets whatsapp_message_synced attribute' do
          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_text_001')
          expect(message.additional_attributes['whatsapp_message_synced']).to be true
          expect(message.additional_attributes['whatsapp_message_type']).to eq('echo')
        end

        it 'creates a conversation if not exists' do
          expect { described_class.new(inbox: inbox, params: params).perform }
            .to change(Conversation, :count).by(1)
        end

        it 'uses existing contact inbox if present' do
          contact = create(:contact, account: inbox.account, phone_number: "+#{wa_id}")
          contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: wa_id)

          expect { described_class.new(inbox: inbox, params: params).perform }
            .not_to change(ContactInbox, :count)

          message = inbox.messages.find_by(source_id: 'wamid.echo_text_001')
          expect(message.conversation.contact_inbox).to eq(contact_inbox)
        end

        it 'does not create duplicate messages' do
          described_class.new(inbox: inbox, params: params).perform
          expect(inbox.messages.where(source_id: 'wamid.echo_text_001').count).to eq(1)

          # Try to process the same message again
          described_class.new(inbox: inbox, params: params).perform
          expect(inbox.messages.where(source_id: 'wamid.echo_text_001').count).to eq(1)
        end
      end

      context 'when valid image message echo with media' do
        let(:media_id) { 'media_id_123456789' }
        let(:params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              id: '987654321',
              changes: [{
                field: 'smb_message_echoes',
                value: {
                  messaging_product: 'whatsapp',
                  metadata: {
                    display_phone_number: whatsapp_channel.phone_number.delete('+'),
                    phone_number_id: '123456789'
                  },
                  message_echoes: [{
                    from: whatsapp_channel.phone_number.delete('+'),
                    to: wa_id,
                    id: 'wamid.echo_image_001',
                    timestamp: '1737392800',
                    type: 'image',
                    image: {
                      id: media_id,
                      mime_type: 'image/jpeg',
                      sha256: 'abc123def456',
                      caption: 'Check out this product photo!'
                    }
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end

        it 'creates message with caption as content' do
          stub_media_download_failure(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_image_001')
          expect(message).to be_present
          expect(message.content).to eq('Check out this product photo!')
          expect(message.message_type).to eq('outgoing')
        end

        it 'creates attachment when media download succeeds' do
          stub_media_download_success(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_image_001')
          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.file_type).to eq('image')
        end

        it 'creates message without attachment when media download fails' do
          stub_media_download_failure(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_image_001')
          expect(message).to be_present
          expect(message.attachments.count).to eq(0)
        end

        it 'increments authorization error count on 401 response' do
          stub_request(:get, whatsapp_channel.media_url(media_id))
            .to_return(status: 401)

          described_class.new(inbox: inbox, params: params).perform

          expect(whatsapp_channel.authorization_error_count).to eq(1)
        end
      end

      context 'when valid audio message echo' do
        let(:media_id) { 'audio_media_id_789' }
        let(:params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              id: '987654321',
              changes: [{
                field: 'smb_message_echoes',
                value: {
                  messaging_product: 'whatsapp',
                  metadata: {
                    display_phone_number: whatsapp_channel.phone_number.delete('+'),
                    phone_number_id: '123456789'
                  },
                  message_echoes: [{
                    from: whatsapp_channel.phone_number.delete('+'),
                    to: wa_id,
                    id: 'wamid.echo_audio_001',
                    timestamp: '1737392900',
                    type: 'audio',
                    audio: {
                      id: media_id,
                      mime_type: 'audio/ogg'
                    }
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end

        it 'creates message with nil content for audio without caption' do
          stub_media_download_failure(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_audio_001')
          expect(message).to be_present
          expect(message.content).to be_nil
        end

        it 'creates audio attachment when download succeeds' do
          stub_media_download_success(media_id, 'audio/ogg', 'spec/assets/sample.png') # Using sample.png as placeholder

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_audio_001')
          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.file_type).to eq('audio')
        end
      end

      context 'when valid document message echo' do
        let(:media_id) { 'doc_media_id_456' }
        let(:params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              id: '987654321',
              changes: [{
                field: 'smb_message_echoes',
                value: {
                  messaging_product: 'whatsapp',
                  metadata: {
                    display_phone_number: whatsapp_channel.phone_number.delete('+'),
                    phone_number_id: '123456789'
                  },
                  message_echoes: [{
                    from: whatsapp_channel.phone_number.delete('+'),
                    to: wa_id,
                    id: 'wamid.echo_doc_001',
                    timestamp: '1737393000',
                    type: 'document',
                    document: {
                      id: media_id,
                      mime_type: 'application/pdf',
                      filename: 'report.pdf',
                      caption: 'Here is the report'
                    }
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end

        it 'creates message with caption as content' do
          stub_media_download_failure(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_doc_001')
          expect(message.content).to eq('Here is the report')
        end

        it 'uses filename as content when caption is absent' do
          params[:entry][0][:changes][0][:value][:message_echoes][0][:document].delete(:caption)
          stub_media_download_failure(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_doc_001')
          expect(message.content).to eq('report.pdf')
        end

        it 'creates file attachment when download succeeds' do
          stub_media_download_success(media_id, 'application/pdf')

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_doc_001')
          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.file_type).to eq('file')
        end
      end

      context 'when valid video message echo' do
        let(:media_id) { 'video_media_id_123' }
        let(:params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              id: '987654321',
              changes: [{
                field: 'smb_message_echoes',
                value: {
                  messaging_product: 'whatsapp',
                  metadata: {
                    display_phone_number: whatsapp_channel.phone_number.delete('+'),
                    phone_number_id: '123456789'
                  },
                  message_echoes: [{
                    from: whatsapp_channel.phone_number.delete('+'),
                    to: wa_id,
                    id: 'wamid.echo_video_001',
                    timestamp: '1737393100',
                    type: 'video',
                    video: {
                      id: media_id,
                      mime_type: 'video/mp4',
                      caption: 'Product demo video'
                    }
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end

        it 'creates video attachment when download succeeds' do
          stub_media_download_success(media_id, 'video/mp4')

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.echo_video_001')
          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.file_type).to eq('video')
        end
      end

      context 'when multiple message echoes in single webhook' do
        let(:params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              id: '987654321',
              changes: [{
                field: 'smb_message_echoes',
                value: {
                  messaging_product: 'whatsapp',
                  metadata: {
                    display_phone_number: whatsapp_channel.phone_number.delete('+'),
                    phone_number_id: '123456789'
                  },
                  message_echoes: [
                    {
                      from: whatsapp_channel.phone_number.delete('+'),
                      to: wa_id,
                      id: 'wamid.echo_multi_001',
                      timestamp: '1737392700',
                      type: 'text',
                      text: { body: 'First message' }
                    },
                    {
                      from: whatsapp_channel.phone_number.delete('+'),
                      to: wa_id,
                      id: 'wamid.echo_multi_002',
                      timestamp: '1737392800',
                      type: 'text',
                      text: { body: 'Second message' }
                    }
                  ]
                }
              }]
            }]
          }.with_indifferent_access
        end

        it 'creates all messages' do
          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.messages.where(source_id: 'wamid.echo_multi_001').count).to eq(1)
          expect(inbox.messages.where(source_id: 'wamid.echo_multi_002').count).to eq(1)
        end
      end

      context 'when invalid params' do
        it 'returns early for non-sync events' do
          params = {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              changes: [{
                field: 'messages',
                value: { messages: [] }
              }]
            }]
          }.with_indifferent_access

          expect { described_class.new(inbox: inbox, params: params).perform }
            .not_to change(Message, :count)
        end

        it 'returns early when value is blank' do
          params = {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              changes: [{
                field: 'smb_message_echoes',
                value: nil
              }]
            }]
          }.with_indifferent_access

          expect { described_class.new(inbox: inbox, params: params).perform }
            .not_to change(Message, :count)
        end

        it 'returns early when message_echoes is missing' do
          params = {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              changes: [{
                field: 'smb_message_echoes',
                value: {
                  messaging_product: 'whatsapp'
                }
              }]
            }]
          }.with_indifferent_access

          expect { described_class.new(inbox: inbox, params: params).perform }
            .not_to change(Message, :count)
        end
      end
    end

    describe 'history sync' do
      let(:thread_wa_id) { '5511888887777' }
      let(:params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            id: '987654321',
            changes: [{
              field: 'history',
              value: {
                messaging_product: 'whatsapp',
                metadata: {
                  display_phone_number: whatsapp_channel.phone_number.delete('+'),
                  phone_number_id: '123456789'
                },
                history: [{
                  threads: [{
                    id: thread_wa_id,
                    messages: [{
                      id: 'wamid.history_001',
                      timestamp: '1737300000',
                      type: 'text',
                      text: { body: 'Historical message' },
                      from: thread_wa_id
                    }]
                  }]
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      it 'creates contact inbox for history messages' do
        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(ContactInbox, :count).by(1)
      end

      it 'creates incoming message from history' do
        described_class.new(inbox: inbox, params: params).perform

        message = inbox.messages.find_by(source_id: 'wamid.history_001')
        expect(message).to be_present
        expect(message.message_type).to eq('incoming')
        expect(message.content).to eq('Historical message')
      end

      it 'marks message as historical' do
        described_class.new(inbox: inbox, params: params).perform

        message = inbox.messages.find_by(source_id: 'wamid.history_001')
        expect(message.additional_attributes['whatsapp_message_type']).to eq('historical')
        expect(message.additional_attributes['whatsapp_message_synced']).to be true
      end

      it 'creates conversation for history with sync attributes' do
        described_class.new(inbox: inbox, params: params).perform

        conversation = inbox.conversations.last
        expect(conversation).to be_present
        expect(conversation.additional_attributes['whatsapp_conversation_synced']).to be true
        expect(conversation.additional_attributes['whatsapp_conversation_sync_timestamp']).to be_present
      end

      it 'skips error type messages' do
        params[:entry][0][:changes][0][:value][:history][0][:threads][0][:messages][0][:type] = 'errors'

        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to change(Message, :count)
      end
    end
  end

  # Helper methods

  def stub_media_download_success(media_id, content_type = 'image/jpeg', file_path = 'spec/assets/sample.png')
    stub_request(:get, whatsapp_channel.media_url(media_id))
      .to_return(
        status: 200,
        body: {
          messaging_product: 'whatsapp',
          url: 'https://chatwoot-assets.local/sample.png',
          mime_type: content_type,
          id: media_id
        }.to_json,
        headers: { 'content-type' => 'application/json' }
      )

    stub_request(:get, 'https://chatwoot-assets.local/sample.png')
      .to_return(
        status: 200,
        body: File.read(file_path),
        headers: { 'content-type' => content_type }
      )
  end

  def stub_media_download_failure(media_id)
    stub_request(:get, whatsapp_channel.media_url(media_id))
      .to_return(status: 404)
  end
end
