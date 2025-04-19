require 'rails_helper'

describe Whatsapp::IncomingMessageWhapiService do
  let!(:account) { create(:account) }
  let!(:whapi_channel) do
    create(:channel_whatsapp, provider: 'whapi', account: account, provider_config: { 'api_key' => 'test_key' })
  end
  let!(:inbox) { create(:inbox, channel: whapi_channel, account: account) }
  let(:whapi_service_instance) { Whatsapp::Providers::WhapiService.new(whatsapp_channel: whapi_channel) }
  let(:sample_png_path) { Rails.root.join('spec/assets/sample.png') }
  let(:sample_ogg_path) { Rails.root.join('spec/assets/sample.ogg') }

  before do
    # Ensure asset directory exists if needed
    FileUtils.mkdir_p(Rails.root.join('spec/assets'))
    # Create dummy asset files if they don't exist
    FileUtils.touch(sample_png_path) unless File.exist?(sample_png_path)
    FileUtils.touch(sample_ogg_path) unless File.exist?(sample_ogg_path)

    # Stub HTTP calls made by WhapiService or the Incoming service
    allow(Whatsapp::Providers::WhapiService).to receive(:new).and_return(whapi_service_instance)
    allow(whapi_service_instance).to receive(:api_headers).and_return({ 'Authorization' => 'Bearer test_key' })
    allow(whapi_service_instance).to receive(:api_base_url).and_return('https://gate.whapi.cloud')
    # Stub contact fetching by default
    allow(whapi_service_instance).to receive(:fetch_contact_info).and_return(nil)
    allow(whapi_service_instance).to receive(:fetch_profile_image).and_return(nil)
    # Stub file downloads
    allow(Down).to receive(:download).and_return(double(read: 'file_content', close: true, path: '/tmp/file', original_filename: 'downloaded_file'))
    allow(::Avatar::AvatarFromUrlJob).to receive(:perform_later)

    # Use test adapter for ActiveJob
    ActiveJob::Base.queue_adapter = :test
  end

  describe '#perform' do
    context 'when receiving an incoming text message event' do
      let(:contact_name) { 'John Doe' }
      let(:phone_number) { '+1234567890' }
      let(:message_id) { 'whapi_msg_123' }
      let(:timestamp) { Time.now.to_i }
      let(:message_text) { 'Hello Chatwoot!' }
      let(:params) do
        {
          messages: [
            {
              id: message_id,
              from: phone_number,
              timestamp: timestamp.to_s,
              type: 'text',
              text: { body: message_text },
              from_me: false # Incoming
            }
          ],
          contacts: [ # Include contact info in webhook
            {
              wa_id: phone_number.delete('+'),
              profile: { name: contact_name }
            }
          ]
        }.with_indifferent_access
      end

      it 'creates contact, conversation, and incoming message' do
        # Stub contact info fetching for this specific number
        allow(whapi_service_instance).to receive(:fetch_contact_info).with(phone_number).and_return({ 'profile' => { 'name' => contact_name } })

        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Contact, :count).by(1)
          .and change(Conversation, :count).by(1)
          .and change(Message, :count).by(1)

        contact = Contact.last
        expect(contact.name).to eq(contact_name)
        expect(contact.phone_number).to eq(phone_number)
        expect(contact.source_id).to eq(phone_number) # source_id set by ContactInboxWithContactBuilder

        conversation = Conversation.last
        expect(conversation.inbox).to eq(inbox)
        expect(conversation.contact).to eq(contact)

        message = Message.last
        expect(message.conversation).to eq(conversation)
        expect(message.message_type).to eq('incoming')
        expect(message.sender).to eq(contact)
        expect(message.content).to eq(message_text)
        expect(message.source_id).to eq(message_id)
        expect(message.created_at).to be_within(1.second).of(Time.at(timestamp))
      end

      it 'updates contact profile information' do
        # Simulate contact exists but needs profile update
        existing_contact = create(:contact, account: account, name: 'Old Name', phone_number: phone_number)
        create(:contact_inbox, contact: existing_contact, inbox: inbox, source_id: phone_number)

        # Stub the API calls for profile update
        allow(whapi_service_instance).to receive(:fetch_contact_info).with(phone_number).and_return({ 'profile' => { 'name' => contact_name }, 'status' => 'Available' })
        allow(whapi_service_instance).to receive(:fetch_profile_image).with(phone_number).and_return({ 'url' => 'http://example.com/image.jpg' })

        described_class.new(inbox: inbox, params: params).perform

        existing_contact.reload
        expect(existing_contact.name).to eq(contact_name)
        expect(existing_contact.additional_attributes['about']).to eq('Available')
        expect(existing_contact.additional_attributes['profile_image']).to eq('http://example.com/image.jpg')
        expect(Avatar::AvatarFromUrlJob).to have_been_enqueued.with(existing_contact, 'http://example.com/image.jpg')
      end

      it 'does not create duplicate message if source_id exists' do
        # Create initial contact and conversation
        contact = create(:contact, account: account, name: contact_name, phone_number: phone_number)
        contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox, source_id: phone_number)
        conversation = create(:conversation, contact: contact, inbox: inbox, account: account, contact_inbox: contact_inbox)
        # Create the message first
        create(:message, conversation: conversation, source_id: message_id, message_type: 'incoming', sender: contact)

        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Message, :count).by(0)
      end
    end

    context 'when receiving an incoming image attachment event' do
      let(:phone_number) { '+1987654321' }
      let(:message_id) { 'whapi_attach_img_123' }
      let(:timestamp) { Time.now.to_i }
      let(:caption) { 'Check this image' }
      let(:media_id) { 'media_img_12345' }
      let(:media_url) { "https://chatwoot-assets.local/sample.png" }
      let(:params) do
        {
          messages: [
            {
              id: message_id,
              from: phone_number,
              timestamp: timestamp.to_s,
              type: 'image',
              image: {
                id: media_id,
                mime_type: 'image/png',
                caption: caption
              },
              from_me: false
            }
          ],
          contacts: [ { wa_id: phone_number.delete('+'), profile: { name: 'Jane Image' } } ]
        }.with_indifferent_access
      end

      before do
        allow(whapi_service_instance).to receive(:get_media_url_from_id).with(media_id).and_return(media_url)
        stub_request(:get, media_url).to_return(
          status: 200, body: File.read(sample_png_path), headers: {'Content-Type': 'image/png'}
        )
        allow(Down).to receive(:download).with(media_url, headers: whapi_service_instance.api_headers, max_size: 50*1024*1024).and_return(
           double(read: File.read(sample_png_path), close: true, path: sample_png_path.to_s, original_filename: 'sample.png')
         )
      end

      it 'creates message with image attachment' do
        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Message, :count).by(1)
          .and change(Attachment, :count).by(1)

        message = Message.last
        attachment = message.attachments.first
        expect(message.message_type).to eq('incoming')
        expect(message.content).to eq(caption)
        expect(attachment.file_type).to eq('image')
        expect(attachment.file.content_type).to eq('image/png')
        expect(attachment.file.filename.to_s).to eq('sample.png')
      end
    end

    context 'when receiving an incoming voice message event' do
      let(:phone_number) { '+1987654322' }
      let(:message_id) { 'whapi_attach_voice_123' }
      let(:timestamp) { Time.now.to_i }
      let(:media_id) { 'media_voice_12345' }
      let(:media_url) { "https://chatwoot-assets.local/sample.ogg" }
      let(:params) do
        {
          messages: [
            {
              id: message_id,
              from: phone_number,
              timestamp: timestamp.to_s,
              type: 'voice',
              voice: {
                id: media_id,
                mime_type: 'audio/ogg; codecs=opus'
              },
              from_me: false
            }
          ],
          contacts: [ { wa_id: phone_number.delete('+'), profile: { name: 'Jane Voice' } } ]
        }.with_indifferent_access
      end

      before do
        allow(whapi_service_instance).to receive(:get_media_url_from_id).with(media_id).and_return(media_url)
        stub_request(:get, media_url).to_return(
          status: 200, body: File.read(sample_ogg_path), headers: {'Content-Type': 'audio/ogg'}
        )
        allow(Down).to receive(:download).with(media_url, headers: whapi_service_instance.api_headers, max_size: 50*1024*1024).and_return(
           double(read: File.read(sample_ogg_path), close: true, path: sample_ogg_path.to_s, original_filename: 'sample.ogg')
         )
      end

      it 'creates message with audio attachment and localized content' do
        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Message, :count).by(1)
          .and change(Attachment, :count).by(1)

        message = Message.last
        attachment = message.attachments.first
        expect(message.message_type).to eq('incoming')
        expect(message.content).to eq(I18n.t('whatsapp.voice_message')) # Check localized content
        expect(attachment.file_type).to eq('audio')
        expect(attachment.file.content_type).to eq('audio/ogg') # Base MIME type
        expect(attachment.file.filename.to_s).to include('ogg')
      end
    end

    context 'when receiving an incoming sticker message event' do
      let(:phone_number) { '+1987654323' }
      let(:message_id) { 'whapi_attach_sticker_123' }
      let(:timestamp) { Time.now.to_i }
      let(:media_id) { 'media_sticker_12345' }
      let(:media_url) { "https://chatwoot-assets.local/sample_sticker.webp" }
      let(:params) do
        {
          messages: [
            {
              id: message_id,
              from: phone_number,
              timestamp: timestamp.to_s,
              type: 'sticker',
              sticker: {
                id: media_id,
                mime_type: 'image/webp'
              },
              from_me: false
            }
          ],
          contacts: [ { wa_id: phone_number.delete('+'), profile: { name: 'Jane Sticker' } } ]
        }.with_indifferent_access
      end

      before do
        allow(whapi_service_instance).to receive(:get_media_url_from_id).with(media_id).and_return(media_url)
        stub_request(:get, media_url).to_return(
          status: 200, body: 'sticker_data', headers: {'Content-Type': 'image/webp'}
        )
        allow(Down).to receive(:download).with(media_url, headers: whapi_service_instance.api_headers, max_size: 50*1024*1024).and_return(
           double(read: 'sticker_data', close: true, path: '/tmp/sticker.webp', original_filename: 'sticker.webp')
         )
      end

      it 'creates message with image attachment (sticker)' do
        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Message, :count).by(1)
          .and change(Attachment, :count).by(1)

        message = Message.last
        attachment = message.attachments.first
        expect(message.message_type).to eq('incoming')
        expect(message.content).to be_nil # Stickers have no primary content
        expect(attachment.file_type).to eq('image') # file_type is image
        expect(attachment.file.content_type).to eq('image/webp')
        expect(attachment.file.filename.to_s).to include('webp')
      end
    end

    context 'when receiving an incoming location message event' do
      let(:phone_number) { '+1987654324' }
      let(:message_id) { 'whapi_location_123' }
      let(:timestamp) { Time.now.to_i }
      let(:latitude) { 37.7749 }
      let(:longitude) { -122.4194 }
      let(:location_name) { 'Chatwoot HQ' }
      let(:params) do
        {
          messages: [
            {
              id: message_id,
              from: phone_number,
              timestamp: timestamp.to_s,
              type: 'location',
              location: {
                latitude: latitude,
                longitude: longitude,
                name: location_name
              },
              from_me: false
            }
          ],
          contacts: [ { wa_id: phone_number.delete('+'), profile: { name: 'Jane Location' } } ]
        }.with_indifferent_access
      end

      it 'creates message with location attachment' do
        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Message, :count).by(1)
          .and change(Attachment, :count).by(1)

        message = Message.last
        attachment = message.attachments.first
        expect(message.message_type).to eq('incoming')
        expect(message.content).to eq(location_name)
        expect(attachment.file_type).to eq('location')
        expect(attachment.external_url).to include("query=#{latitude},#{longitude}")
        expect(attachment.fallback_title).to eq(location_name)
        expect(attachment.metadata['coordinates_lat']).to eq(latitude)
        expect(attachment.metadata['coordinates_long']).to eq(longitude)
      end
    end

    context 'when receiving an outgoing text message event (not in Chatwoot)' do
      let(:recipient_number) { '+1122334455' }
      let(:message_id) { 'whapi_outgoing_456' }
      let(:timestamp) { Time.now.to_i }
      let(:message_text) { 'Message sent from phone' }
      let(:params) do
        {
          messages: [
            {
              id: message_id,
              to: recipient_number, # Recipient for outgoing
              timestamp: timestamp.to_s,
              type: 'text',
              text: { body: message_text },
              from_me: true # Outgoing
            }
          ]
          # No 'contacts' field usually for outgoing webhooks
        }.with_indifferent_access
      end

      it 'creates contact (recipient), conversation, and outgoing message' do
        # Stub fetching contact name for recipient
        allow(whapi_service_instance).to receive(:fetch_contact_info).with(recipient_number).and_return({ 'profile' => { 'name' => 'Recipient Name' } })

        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Contact, :count).by(1)
          .and change(Conversation, :count).by(1)
          .and change(Message, :count).by(1)

        contact = Contact.last
        expect(contact.name).to eq('Recipient Name')
        expect(contact.phone_number).to eq(recipient_number)

        conversation = Conversation.last
        expect(conversation.inbox).to eq(inbox)
        expect(conversation.contact).to eq(contact)

        message = Message.last
        expect(message.conversation).to eq(conversation)
        expect(message.message_type).to eq('outgoing')
        expect(message.sender).to be_nil # No agent sender
        expect(message.content).to eq(message_text)
        expect(message.source_id).to eq(message_id)
      end
    end

     context 'when receiving an outgoing attachment message event (not in Chatwoot)' do
        let(:recipient_number) { '+1122334455' }
        let(:message_id) { 'whapi_outgoing_attach_789' }
        let(:timestamp) { Time.now.to_i }
        let(:caption) { 'Sent image from phone' }
        let(:media_id) { 'media_67890' }
        let(:media_url) { "https://chatwoot-assets.local/sample_outgoing.jpg" }
        let(:params) do
          {
            messages: [
              {
                id: message_id,
                to: recipient_number,
                timestamp: timestamp.to_s,
                type: 'image',
                image: {
                  id: media_id,
                  mime_type: 'image/jpeg',
                  caption: caption
                },
                from_me: true
              }
            ]
          }.with_indifferent_access
        end

        before do
          allow(whapi_service_instance).to receive(:get_media_url_from_id).with(media_id).and_return(media_url)
          stub_request(:get, media_url).to_return(status: 200, body: 'jpeg_data', headers: {'Content-Type': 'image/jpeg'})
          allow(Down).to receive(:download).with(media_url, headers: whapi_service_instance.api_headers, max_size: 50*1024*1024).and_return(
             double(read: 'jpeg_data', close: true, path: '/tmp/sample_outgoing.jpg', original_filename: 'sample_outgoing.jpg')
           )
        end

       it 'creates outgoing message with attachment' do
          # Stub fetching contact name for recipient
          allow(whapi_service_instance).to receive(:fetch_contact_info).with(recipient_number).and_return({ 'profile' => { 'name' => 'Recipient Name' } })

          expect { described_class.new(inbox: inbox, params: params).perform }
            .to change(Contact, :count).by(1)
            .and change(Conversation, :count).by(1)
            .and change(Message, :count).by(1)
            .and change(Attachment, :count).by(1)

          message = Message.last
          expect(message.message_type).to eq('outgoing')
          expect(message.sender).to be_nil
          expect(message.content).to eq(caption)
          expect(message.source_id).to eq(message_id)
          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.file_type).to eq('image')
       end
     end

    context 'when receiving an outgoing message event (already in Chatwoot)' do
      let(:recipient_number) { '+1555666777' }
      let(:message_id) { 'whapi_existing_outgoing_111' } # Matches existing source_id
      let(:timestamp) { Time.now.to_i }
      let(:message_text) { 'Sent via Chatwoot originally' }
      let!(:contact) { create(:contact, account: account, phone_number: recipient_number) }
      let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
      let!(:conversation) { create(:conversation, contact: contact, inbox: inbox, account: account, contact_inbox: contact_inbox) }
      let!(:existing_message) do
        create(:message,
               message_type: :outgoing,
               sender: nil, # Or an agent if sent via UI
               content: message_text,
               conversation: conversation,
               inbox: inbox,
               account: account,
               source_id: message_id, # Has the source ID already
               status: 'sent')
      end
      let(:params) do
        {
          messages: [
            {
              id: message_id,
              to: recipient_number,
              timestamp: timestamp.to_s,
              type: 'text',
              text: { body: message_text },
              status: 'delivered', # Status update in the same payload
              from_me: true
            }
          ]
        }.with_indifferent_access
      end

      it 'updates the status of the existing message and does not create a new one' do
        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change(Message, :count).by(0) # No new message

        existing_message.reload
        expect(existing_message.status).to eq('delivered')
        expect(existing_message.source_id).to eq(message_id) # Should remain the same
      end
    end

    context 'when receiving a status update event' do
      let(:contact_number) { '+1777888999' }
      let(:message_id) { 'whapi_status_update_msg' }
      let!(:contact) { create(:contact, account: account, phone_number: contact_number) }
      let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
      let!(:conversation) { create(:conversation, contact: contact, inbox: inbox, account: account, contact_inbox: contact_inbox) }
      let!(:message) do
        create(:message,
               message_type: :outgoing, # Status usually for outgoing
               conversation: conversation,
               source_id: message_id,
               status: 'sent')
      end

      it 'updates the status to delivered' do
        status_params = {
          status: {
            id: message_id,
            status: 'delivered',
            timestamp: Time.now.to_i.to_s,
            to: contact_number,
            from_me: true
          }
        }.with_indifferent_access

        described_class.new(inbox: inbox, params: status_params).perform
        expect(message.reload.status).to eq('delivered')
      end

      it 'updates the status to read' do
        status_params = {
          status: {
            id: message_id,
            status: 'read',
            timestamp: Time.now.to_i.to_s,
            to: contact_number,
            from_me: true
          }
        }.with_indifferent_access

        described_class.new(inbox: inbox, params: status_params).perform
        expect(message.reload.status).to eq('read')
      end

      it 'updates the status to failed with error message' do
        error_details = { code: 131_051, title: 'Message failed to send' }.to_json
        status_params = {
          status: {
            id: message_id,
            status: 'failed',
            timestamp: Time.now.to_i.to_s,
            to: contact_number,
            from_me: true,
            error: error_details
          }
        }.with_indifferent_access

        described_class.new(inbox: inbox, params: status_params).perform
        message.reload
        expect(message.status).to eq('failed')
        expect(message.external_error).to eq(error_details)
      end

      it 'does not update status if message not found' do
        status_params = {
          status: {
            id: 'non_existent_msg_id',
            status: 'read',
            timestamp: Time.now.to_i.to_s,
            to: contact_number,
            from_me: true
          }
        }.with_indifferent_access

        expect { described_class.new(inbox: inbox, params: status_params).perform }
          .not_to change { message.reload.status }
      end
    end

    # Add tests for edge cases: unsupported types, download errors, missing recipient in outgoing, etc.

  end
end 