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
end
