require 'rails_helper'

RSpec.describe Channels::Whatsapp::ZapiReadMessageJob do
  let(:whatsapp_channel) do
    create(:channel_whatsapp,
           provider: 'zapi',
           sync_templates: false,
           validate_provider_config: false,
           provider_config: {
             'instance_id' => 'test-instance',
             'token' => 'test-token',
             'client_token' => 'test-client-token'
           })
  end

  let(:phone) { '551187654321' }
  let(:message_source_id) { 'msg_123' }
  let(:api_base_path) { Whatsapp::Providers::WhatsappZapiService::API_BASE_PATH }
  let(:api_instance_path_with_token) { "#{api_base_path}/instances/test-instance/token/test-token" }

  def stub_headers
    {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Type' => 'application/json',
      'Client-Token' => 'test-client-token',
      'User-Agent' => 'Ruby'
    }
  end

  describe '#perform' do
    context 'when response is successful' do
      it 'sends a read message request to Z-API' do
        stub_request(:post, "#{api_instance_path_with_token}/read-message")
          .with(
            headers: stub_headers,
            body: {
              phone: phone,
              messageId: message_source_id
            }.to_json
          )
          .to_return(status: 200)

        described_class.perform_now(whatsapp_channel, phone, message_source_id)

        expect(a_request(:post, "#{api_instance_path_with_token}/read-message")
          .with(
            headers: stub_headers,
            body: {
              phone: phone,
              messageId: message_source_id
            }.to_json
          )).to have_been_made.once
      end
    end

    context 'when response is unsuccessful' do
      it 'logs the error' do
        stub_request(:post, "#{api_instance_path_with_token}/read-message")
          .with(headers: stub_headers)
          .to_return(status: 400, body: 'error message')

        allow(Rails.logger).to receive(:error)

        described_class.perform_now(whatsapp_channel, phone, message_source_id)

        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end
end
