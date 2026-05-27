require 'rails_helper'

describe Whatsapp::TemplateMediaResolverService do
  describe '#call' do
    let(:blob) { get_blob_for('spec/assets/avatar.png', 'image/png') }

    it 'resolves media_blob_id to media_url' do
      header_data = {
        'media_type' => 'image',
        'media_blob_id' => blob.signed_id
      }

      result = described_class.new(header_data: header_data).call

      expect(result['media_blob_id']).to be_nil
      expect(result['media_url']).to be_present
      expect(result['media_type']).to eq('image')
    end

    it 'raises error when media_url and media_blob_id are both provided' do
      header_data = {
        'media_type' => 'image',
        'media_blob_id' => blob.signed_id,
        'media_url' => 'https://example.com/image.png'
      }

      expect { described_class.new(header_data: header_data).call }
        .to raise_error(ArgumentError, 'Provide either media URL or uploaded file, not both.')
    end
  end
end
