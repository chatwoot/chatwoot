require 'rails_helper'

RSpec.describe Tiktok::Client do
  let(:client) { described_class.new(business_id: 'biz-123', access_token: 'token-123') }
  let(:response) { instance_double(HTTParty::Response) }

  describe '#image_send_capable?' do
    before do
      allow(HTTParty).to receive(:get).and_return(response)
      allow(GlobalConfigService).to receive(:load).with('TIKTOK_API_VERSION', 'v1.3').and_return('v1.3')
    end

    it 'returns true when IMAGE_SEND capability is enabled' do
      allow(client).to receive(:process_json_response).with(
        response,
        'Failed to fetch TikTok message capabilities'
      ).and_return(
        {
          'data' => {
            'capability_infos' => [
              { 'capability_type' => 'IMAGE_SEND', 'capability_result' => true }
            ]
          }
        }
      )

      result = client.image_send_capable?('tt-conv-1')

      expect(result).to be(true)
      expect(HTTParty).to have_received(:get).with(
        'https://business-api.tiktok.com/open_api/v1.3/business/message/capabilities/get/',
        query: {
          business_id: 'biz-123',
          conversation_id: 'tt-conv-1',
          conversation_type: 'SINGLE',
          capability_types: '["IMAGE_SEND"]'
        },
        headers: { 'Access-Token': 'token-123' }
      )
    end

    it 'returns false when IMAGE_SEND capability is not enabled' do
      allow(client).to receive(:process_json_response).with(
        response,
        'Failed to fetch TikTok message capabilities'
      ).and_return(
        {
          'data' => {
            'capability_infos' => [
              { 'capability_type' => 'IMAGE_SEND', 'capability_result' => false }
            ]
          }
        }
      )

      result = client.image_send_capable?('tt-conv-1')

      expect(result).to be(false)
    end
  end

  describe '#upload_media' do
    let(:connection) { instance_double(Faraday::Connection) }
    let(:request) { instance_double(Faraday::Request, headers: {}) }
    let(:response) { instance_double(Faraday::Response, success?: true, body: response_body) }
    let(:response_body) do
      {
        code: 0,
        message: 'OK',
        data: { media_id: 'media-123' }
      }.to_json
    end
    let(:blob) do
      instance_double(
        ActiveStorage::Blob,
        content_type: 'image/png',
        filename: ActiveStorage::Filename.new('avatar.png')
      )
    end

    before do
      allow(GlobalConfigService).to receive(:load).with('TIKTOK_API_VERSION', 'v1.3').and_return('v1.3')
      allow(Faraday).to receive(:new).and_return(connection)
      allow(blob).to receive(:open) do |&block|
        File.open(Rails.root.join('spec/assets/avatar.png'), 'rb', &block)
      end
    end

    it 'posts media upload with access token header' do
      captured_endpoint = nil
      allow(connection).to receive(:post) do |endpoint, _payload, &block|
        captured_endpoint = endpoint
        block.call(request)
        response
      end

      media_id = client.send(:upload_media, blob)

      expect(media_id).to eq('media-123')
      expect(captured_endpoint).to eq('https://business-api.tiktok.com/open_api/v1.3/business/message/media/upload/')
      expect(request.headers['Access-Token']).to eq('token-123')
    end

    it 'uploads media as a multipart file with filename and content type' do
      captured_payload = nil
      allow(connection).to receive(:post) do |_endpoint, payload, &block|
        captured_payload = payload
        block.call(request)
        response
      end

      client.send(:upload_media, blob)

      expect(captured_payload[:business_id]).to eq('biz-123')
      expect(captured_payload[:media_type]).to eq('IMAGE')
      expect(captured_payload[:file]).to be_a(Faraday::Multipart::FilePart)
      expect(captured_payload[:file].content_type).to eq('image/png')
      expect(captured_payload[:file].original_filename).to eq('avatar.png')
    end
  end

  describe '#send_media_message' do
    let(:file) { Struct.new(:blob).new('blob') }
    let(:attachment) { instance_double(Attachment, file: file) }

    it 'sends image messages' do
      allow(client).to receive(:upload_media).with('blob', 'IMAGE').and_return('media-123')
      allow(client).to receive(:send_message).and_return('tt-msg-123')

      message_id = client.send_media_message('tt-conv-1', attachment)

      expect(message_id).to eq('tt-msg-123')
      expect(client).to have_received(:send_message).with('tt-conv-1', 'IMAGE', 'media-123')
    end
  end
end
