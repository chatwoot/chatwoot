require 'rails_helper'

RSpec.describe ChatscommerceService::ConfigurationService do
  let(:service) { described_class.new }
  let(:store_id) { SecureRandom.uuid }
  let(:api_url) { 'https://test.chatscommerce.com' }

  before do
    # Mock the method that returns the API url to ensure we don't make real calls.
    allow(service).to receive(:chatscommerce_api_url).and_return(api_url)
  end

  describe '#create_default_store_configs' do
    # We create a small, fake hash of default configs for our test.
    # This makes the test independent of the actual default values.
    let(:default_configs) do
      {
        'notification_config' => { notifications: 'enabled' },
        'messaging_config' => { sms: 'disabled' },
        'general_store_config' => { currency: 'USD' },
        'ecommerce_config' => { enabled: true },
        'calendly_config' => { link: 'https://calendly.com/test' },
        'conversation_config' => { auto_reply: false }
      }
    end
    

    before do
      # We stub the `default_configs` method on our service to return our fake hash.
      allow(service).to receive(:default_configs).and_return(default_configs)
    end

    context 'when all configurations are created successfully' do
      it 'calls create_configuration for each default config' do
        # We expect the `create_configuration` method to be called once for each
        # item in our fake `default_configs` hash.
        default_configs.each do |key, data|
          expect(service).to receive(:create_configuration).with(store_id, key, data).once
        end

        # We run the method that should trigger the calls.
        service.create_default_store_configs(store_id)
      end
    end

    context 'when creating a configuration fails' do
      it 'raises a ConfigurationError and stops' do
        # In this scenario, we simulate the second call failing.
        allow(service).to receive(:create_configuration)
          .with(store_id, 'notification_config', anything) # The first call succeeds.
        allow(service).to receive(:create_configuration)
          .with(store_id, 'messaging_config', anything) # The second call fails.
          .and_raise(StandardError, 'API Error')

        # We assert that our service raises its custom error, wrapping the original error message.
        expect do
          service.create_default_store_configs(store_id)
        end.to raise_error(
          ChatscommerceService::ConfigurationService::ConfigurationError,
          /Configuration creation failed: API Error/
        )
      end
    end
  end

  describe '#create_configuration' do
    let(:config_key) { 'test_config' }
    let(:config_data) { { setting: 'value' } }
    let(:request_body) do
      {
        configuration: {
          id: nil,
          key: config_key,
          data: config_data,
          store_id: store_id
        }
      }.to_json
    end
    let(:api_endpoint) { "#{api_url}/api/configurations/" }

    context 'when the API call is successful' do
      let(:success_response) { { 'id' => '123', 'key' => config_key }.to_json }

      before do
        # We stub the HTTP request, expecting the correct body,
        # and tell it to return a successful response.
        stub_request(:put, api_endpoint)
          .with(body: request_body)
          .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the parsed response' do
        response = service.create_configuration(store_id, config_key, config_data)
        expect(response).to eq(JSON.parse(success_response))
      end
    end

    context 'when the API call fails' do
      before do
        # We stub the HTTP request to return a 500 server error.
        stub_request(:put, api_endpoint)
          .with(body: request_body)
          .to_return(status: 500, body: { error: 'Server Error' }.to_json)
      end

      it 'raises a ConfigurationError' do
        expect do
          service.create_configuration(store_id, config_key, config_data)
        end.to raise_error(ChatscommerceService::ConfigurationService::ConfigurationError, /Unexpected error: 500 - \{\"error\":\"Server Error\"\}/)
      end
    end
  end
end