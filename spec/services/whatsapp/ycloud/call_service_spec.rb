require 'rails_helper'

describe Whatsapp::Ycloud::CallService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#connect' do
    it 'initiates a call with business phone number' do
      stub = stub_request(:post, "#{api_base}/whatsapp/calls/connect")
        .with(body: hash_including({ 'to' => '+1234567890', 'from' => whatsapp_channel.phone_number }))
        .to_return(status: 200, body: { callId: 'call_001' }.to_json, headers: headers)

      response = service.connect(to: '+1234567890', sdpOffer: 'sdp_data')
      expect(stub).to have_been_requested
      expect(response.parsed_response['callId']).to eq('call_001')
    end
  end

  describe '#pre_accept' do
    it 'sends pre-accept for incoming call' do
      stub = stub_request(:post, "#{api_base}/whatsapp/calls/pre-accept")
        .with(body: { callId: 'call_001' }.to_json)
        .to_return(status: 200, body: '{}', headers: headers)

      service.pre_accept(callId: 'call_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#accept' do
    it 'accepts a call with SDP answer' do
      stub = stub_request(:post, "#{api_base}/whatsapp/calls/accept")
        .with(body: hash_including({ 'callId' => 'call_001' }))
        .to_return(status: 200, body: '{}', headers: headers)

      service.accept(callId: 'call_001', sdpAnswer: 'sdp_answer')
      expect(stub).to have_been_requested
    end
  end

  describe '#terminate' do
    it 'terminates an active call' do
      stub = stub_request(:post, "#{api_base}/whatsapp/calls/terminate")
        .to_return(status: 200, body: '{}', headers: headers)

      service.terminate(callId: 'call_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#reject' do
    it 'rejects an incoming call' do
      stub = stub_request(:post, "#{api_base}/whatsapp/calls/reject")
        .to_return(status: 200, body: '{}', headers: headers)

      service.reject(callId: 'call_001')
      expect(stub).to have_been_requested
    end
  end
end
