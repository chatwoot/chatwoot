require 'rails_helper'

describe Whatsapp::MediaUploadService do
  subject(:service) { described_class.new(whatsapp_channel, attachment) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox)
  end
  let(:file_path) { Rails.root.join('spec/assets/avatar.png') }
  let(:attachment) do
    attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
    attachment.file.attach(io: file_path.open, filename: 'avatar.png', content_type: 'image/png')
    attachment.save!
    attachment
  end
  let(:upload_url) { 'https://graph.facebook.com/v22.0/123456789/media' }

  describe '#perform' do
    it 'uploads the file as multipart form data and returns the media object' do
      stub_request(:post, upload_url)
        .to_return(status: 200, body: { id: 'media_abc123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(service.perform).to eq({ 'id' => 'media_abc123' })
      expect(WebMock).to(have_requested(:post, upload_url).with do |request|
        request.headers['Authorization'] == 'Bearer test_key' &&
          request.body.b.include?('name="file"; filename="avatar.png"'.b) &&
          request.body.b.include?('Content-Type: image/png'.b) &&
          request.body.b.include?(file_path.binread) &&
          request.body.b.include?("name=\"messaging_product\"\r\n\r\nwhatsapp".b)
      end)
    end

    it 'returns nil when Meta rejects the upload' do
      stub_request(:post, upload_url)
        .to_return(status: 429, body: { error: { message: 'rate limited' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(service.perform).to be_nil
    end

    it 'returns nil when the upload request fails' do
      stub_request(:post, upload_url).to_timeout

      expect(service.perform).to be_nil
    end

    it 'returns nil when the attachment has no file' do
      attachment = message.attachments.create!(account_id: message.account_id, file_type: :location)

      expect(described_class.new(whatsapp_channel, attachment).perform).to be_nil
    end

    it 'returns nil without uploading when WHATSAPP_MEDIA_UPLOAD_STRATEGY is link' do
      with_modified_env WHATSAPP_MEDIA_UPLOAD_STRATEGY: 'link' do
        expect(service.perform).to be_nil
      end

      expect(WebMock).not_to have_requested(:post, upload_url)
    end
  end
end
