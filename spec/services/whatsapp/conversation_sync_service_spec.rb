require 'rails_helper'

describe Whatsapp::ConversationSyncService do
  describe '#perform' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
    let(:inbox) { whatsapp_channel.inbox }

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

      it 'does not create duplicate messages' do
        described_class.new(inbox: inbox, params: params).perform
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.where(source_id: 'wamid.history_001').count).to eq(1)
      end

      it 'skips error type messages' do
        params[:entry][0][:changes][0][:value][:history][0][:threads][0][:messages][0][:type] = 'errors'

        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to change(Message, :count)
      end

      it 'returns early for non-history events' do
        params[:entry][0][:changes][0][:field] = 'messages'

        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to change(Message, :count)
      end

      it 'returns early when value is blank' do
        params[:entry][0][:changes][0][:value] = nil

        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to change(Message, :count)
      end

      context 'when history message has media' do
        let(:media_id) { 'media_id_123456789' }
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
                        id: 'wamid.history_img_001',
                        timestamp: '1737300000',
                        type: 'image',
                        image: { id: media_id, mime_type: 'image/jpeg', caption: 'A photo' },
                        from: thread_wa_id
                      }]
                    }]
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end

        it 'creates attachment when media download succeeds' do
          stub_media_download_success(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.history_img_001')
          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.file_type).to eq('image')
        end

        it 'creates message without attachment when media download fails' do
          stub_media_download_failure(media_id)

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.messages.find_by(source_id: 'wamid.history_img_001')
          expect(message).to be_present
          expect(message.attachments.count).to eq(0)
        end
      end
    end
  end

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
