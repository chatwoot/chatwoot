require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:calls_url) { 'https://graph.facebook.com/v13.0/123456789/calls' }
  let(:messages_url) { 'https://graph.facebook.com/v13.0/123456789/messages' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  before { stub_request(:get, /message_templates/) }

  describe 'call action methods' do
    it 'POSTs the action body with the SDP answer and returns true on success' do
      stub_request(:post, calls_url)
        .with(body: { messaging_product: 'whatsapp', call_id: 'WACALL', action: 'pre_accept',
                      session: { sdp: 'sdp_answer', sdp_type: 'answer' } }.to_json)
        .to_return(status: 200, body: '{}', headers: headers)

      expect(service.pre_accept_call('WACALL', 'sdp_answer')).to be true
    end

    it 'returns false when Meta responds with a non-success status' do
      stub_request(:post, calls_url).to_return(status: 400, body: '{}', headers: headers)

      expect(service.reject_call('WACALL')).to be false
    end
  end

  describe '#send_call_permission_request' do
    it 'returns the parsed body on success' do
      stub_request(:post, messages_url)
        .with(body: hash_including(messaging_product: 'whatsapp', to: '15551234567', type: 'interactive'))
        .to_return(status: 200, body: { messages: [{ id: 'wamid' }] }.to_json, headers: headers)

      expect(service.send_call_permission_request('15551234567')).to eq('messages' => [{ 'id' => 'wamid' }])
    end
  end

  describe '#initiate_call' do
    it 'returns the parsed body on success' do
      stub_request(:post, calls_url)
        .with(body: { messaging_product: 'whatsapp', to: '15551234567', type: 'audio',
                      session: { sdp: 'sdp_offer', sdp_type: 'offer' } }.to_json)
        .to_return(status: 200, body: { messages: [{ id: 'wacall_1' }] }.to_json, headers: headers)

      expect(service.initiate_call('15551234567', 'sdp_offer')).to eq('messages' => [{ 'id' => 'wacall_1' }])
    end

    it 'raises Voice::CallErrors::NoCallPermission when Meta returns error code 138006' do
      stub_request(:post, calls_url).to_return(
        status: 400,
        body: { error: { code: 138_006, error_user_msg: 'No call permission' } }.to_json,
        headers: headers
      )

      expect { service.initiate_call('15551234567', 'sdp_offer') }
        .to raise_error(Voice::CallErrors::NoCallPermission, 'No call permission')
    end

    it 'raises Voice::CallErrors::CallFailed with a fallback message when the error body is non-JSON' do
      stub_request(:post, calls_url).to_return(status: 502, body: '<html>502 Bad Gateway</html>',
                                               headers: { 'Content-Type' => 'text/html' })

      expect { service.initiate_call('15551234567', 'sdp_offer') }
        .to raise_error(Voice::CallErrors::CallFailed, 'Failed to initiate call')
    end
  end
end
