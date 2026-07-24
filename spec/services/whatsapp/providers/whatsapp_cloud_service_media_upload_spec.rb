# frozen_string_literal: true

require 'rails_helper'

# Focused spec for the direct media upload behaviour introduced in
# Whatsapp::Providers::WhatsappCloudService to fix issue #13540.
RSpec.describe Whatsapp::Providers::WhatsappCloudService do
  let(:channel) do
    instance_double(
      'Channel::Whatsapp',
      provider_config: {
        'api_key' => 'test_key',
        'phone_number_id' => '111',
        'business_account_id' => '222'
      },
      inbox: instance_double('Inbox', id: 1),
      account_id: 1
    )
  end

  subject(:service) { described_class.new(whatsapp_channel: channel) }

  describe '#build_attachment_content (private)' do
    let(:attachment) do
      instance_double('Attachment',
                      id: 1,
                      file_type: 'image',
                      file: instance_double('ActiveStorage::Attached::One',
                                           content_type: 'image/jpeg',
                                           filename: ActiveStorage::Filename.new('img.jpg'),
                                           attached?: true,
                                           blob: instance_double('ActiveStorage::Blob', content_type: 'image/jpeg')),
                      download_url: 'https://s3.example.com/img.jpg',
                      meta: {})
    end

    let(:message) do
      instance_double('Message', outgoing_content: 'check this out',
                                  content_attributes: {})
    end

    context 'when WHATSAPP_MEDIA_UPLOAD_STRATEGY=direct (default)' do
      before do
        stub_const('ENV', ENV.to_h.merge('WHATSAPP_MEDIA_UPLOAD_STRATEGY' => 'direct'))
        allow(Whatsapp::MediaUploadService).to receive(:new).and_return(
          instance_double('Whatsapp::MediaUploadService', upload: 'media_xyz')
        )
      end

      it 'uses media_id instead of link' do
        result = service.send(:build_attachment_content, 'image', attachment, message)
        expect(result['id']).to eq('media_xyz')
        expect(result).not_to have_key('link')
      end
    end

    context 'when WHATSAPP_MEDIA_UPLOAD_STRATEGY=link' do
      before do
        stub_const('ENV', ENV.to_h.merge('WHATSAPP_MEDIA_UPLOAD_STRATEGY' => 'link'))
      end

      it 'falls back to legacy link-based sending' do
        result = service.send(:build_attachment_content, 'image', attachment, message)
        expect(result['link']).to eq('https://s3.example.com/img.jpg')
        expect(result).not_to have_key('id')
      end
    end

    context 'when direct upload raises an error' do
      before do
        stub_const('ENV', ENV.to_h.merge('WHATSAPP_MEDIA_UPLOAD_STRATEGY' => 'direct'))
        allow(Whatsapp::MediaUploadService).to receive(:new).and_return(
          instance_double('Whatsapp::MediaUploadService').tap do |s|
            allow(s).to receive(:upload).and_raise(StandardError, 'network error')
          end
        )
      end

      it 'gracefully falls back to link' do
        result = service.send(:build_attachment_content, 'image', attachment, message)
        expect(result['link']).to eq('https://s3.example.com/img.jpg')
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with(/Direct media upload failed/)
        service.send(:build_attachment_content, 'image', attachment, message)
      end
    end
  end
end
