require 'rails_helper'

describe Whatsapp::Ycloud::MultiChannelService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#send_sms' do
    it 'sends an SMS' do
      stub = stub_request(:post, "#{api_base}/sms/send")
        .with(body: hash_including({ 'to' => '+1234567890', 'text' => 'Hello' }))
        .to_return(status: 200, body: { id: 'sms_001' }.to_json, headers: headers)

      response = service.send_sms(to: '+1234567890', text: 'Hello')
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('sms_001')
    end
  end

  describe '#send_email' do
    it 'sends an email' do
      stub = stub_request(:post, "#{api_base}/emails/send")
        .with(body: hash_including({ 'to' => 'user@example.com', 'subject' => 'Test' }))
        .to_return(status: 200, body: { id: 'email_001' }.to_json, headers: headers)

      response = service.send_email(to: 'user@example.com', from: 'noreply@test.com', subject: 'Test', content: 'Hello')
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('email_001')
    end
  end

  describe '#send_voice' do
    it 'sends a voice message' do
      stub = stub_request(:post, "#{api_base}/voice/send")
        .with(body: hash_including({ 'to' => '+1234567890' }))
        .to_return(status: 200, body: { id: 'voice_001' }.to_json, headers: headers)

      response = service.send_voice(to: '+1234567890', verificationCode: '123456', language: 'en')
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('voice_001')
    end
  end

  describe '#start_verification' do
    it 'starts OTP verification' do
      stub = stub_request(:post, "#{api_base}/verify/verifications")
        .with(body: hash_including({ 'to' => '+1234567890', 'channel' => 'whatsapp' }))
        .to_return(status: 200, body: { id: 'ver_001', status: 'pending' }.to_json, headers: headers)

      response = service.start_verification(to: '+1234567890', channel: 'whatsapp')
      expect(stub).to have_been_requested
      expect(response.parsed_response['status']).to eq('pending')
    end
  end

  describe '#check_verification' do
    it 'checks OTP code' do
      stub = stub_request(:post, "#{api_base}/verify/verificationChecks")
        .with(body: hash_including({ 'verificationId' => 'ver_001', 'code' => '123456' }))
        .to_return(status: 200, body: { id: 'ver_001', status: 'approved' }.to_json, headers: headers)

      response = service.check_verification(verificationId: 'ver_001', code: '123456')
      expect(stub).to have_been_requested
      expect(response.parsed_response['status']).to eq('approved')
    end
  end
end
