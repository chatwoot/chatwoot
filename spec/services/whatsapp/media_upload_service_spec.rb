# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::MediaUploadService do
  let(:channel) do
    instance_double(
      'Channel::Whatsapp',
      provider_config: {
        'api_key' => 'test_api_key',
        'phone_number_id' => '123456789'
      }
    )
  end

  let(:blob) do
    instance_double(
      ActiveStorage::Blob,
      content_type: 'image/jpeg',
      filename: ActiveStorage::Filename.new('photo.jpg')
    )
  end

  let(:file_double) do
    instance_double(
      ActiveStorage::Attached::One,
      download: 'fake_binary_content',
      content_type: 'image/jpeg',
      filename: ActiveStorage::Filename.new('photo.jpg'),
      blob: blob
    )
  end

  let(:attachment) do
    instance_double('Attachment', id: 42, file: file_double)
  end

  subject(:service) { described_class.new(channel: channel, attachment: attachment) }

  describe '#upload' do
    context 'when the upload succeeds' do
      before do
        stub_request(:post, 'https://graph.facebook.com/v18.0/123456789/media')
          .to_return(
            status: 200,
            body: { id: 'media_abc123' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the media_id' do
        expect(service.upload).to eq('media_abc123')
      end

      it 'sends Authorization header' do
        service.upload
        expect(WebMock).to have_requested(:post, 'https://graph.facebook.com/v18.0/123456789/media')
          .with(headers: { 'Authorization' => 'Bearer test_api_key' })
      end
    end

    context 'when the API returns an error' do
      before do
        stub_request(:post, 'https://graph.facebook.com/v18.0/123456789/media')
          .to_return(
            status: 400,
            body: { error: { message: 'Invalid media type' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error' do
        expect { service.upload }.to raise_error(RuntimeError, /Invalid media type/)
      end
    end

    context 'when the API returns 429 rate limited' do
      before do
        stub_request(:post, 'https://graph.facebook.com/v18.0/123456789/media')
          .to_return(
            status: 429,
            body: { error: { message: 'Too Many Requests' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises and logs an error' do
        expect(Rails.logger).to receive(:error).with(/Failed for attachment 42/)
        expect { service.upload }.to raise_error(RuntimeError)
      end
    end

    context 'when WHATSAPP_CLOUD_BASE_URL is customised' do
      before do
        stub_const('ENV', ENV.to_h.merge('WHATSAPP_CLOUD_BASE_URL' => 'https://custom.meta.local'))
        stub_request(:post, 'https://custom.meta.local/v18.0/123456789/media')
          .to_return(status: 200, body: { id: 'media_custom' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'uses the custom base URL' do
        expect(service.upload).to eq('media_custom')
      end
    end
  end
end
