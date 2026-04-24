require 'rails_helper'

describe Messages::TemplateMediaAttachmentService do
  describe '#perform' do
    let(:account) { create(:account) }
    let(:inbox) do
      create(:inbox, channel: create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false), account: account)
    end
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing) }
    let(:blob) { get_blob_for('spec/assets/avatar.png', 'image/png') }
    let(:template_params) do
      {
        'processed_params' => {
          'header' => {
            'media_blob_id' => blob.signed_id,
            'media_type' => 'image'
          }
        }
      }
    end

    it 'handles non-array attachments without raising error' do
      single_attachment = Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')

      expect do
        described_class.new(message: message, attachments: single_attachment, template_params: template_params).perform
      end.not_to raise_error
    end
  end
end
