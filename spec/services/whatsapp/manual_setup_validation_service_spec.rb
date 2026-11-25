require 'rails_helper'

describe Whatsapp::ManualSetupValidationService do
  subject(:service) { described_class.new(waba_id: 'waba', phone_number_id: 'phone-id', access_token: 'token', app_secret: app_secret) }

  let(:app_secret) { 'customer_secret' }
  let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }

  before do
    allow(Whatsapp::FacebookApiClient).to receive(:new).with('token').and_return(api_client)
    allow(api_client).to receive_messages(
      fetch_all_phone_numbers: [{ 'id' => 'phone-id', 'display_phone_number' => '+55 11 98888-7777', 'verified_name' => 'Acme' }],
      fetch_phone_number: { 'status' => 'CONNECTED' },
      fetch_message_templates: { 'data' => [] },
      fetch_permissions: { 'data' => [{ 'permission' => 'whatsapp_business_messaging', 'status' => 'granted' }] },
      app_secret_matches?: true
    )
  end

  it 'accepts the secret of the app that issued the token' do
    expect(service.perform).to include(phone_number_id: 'phone-id')
    expect(api_client).to have_received(:app_secret_matches?).with('customer_secret')
  end

  context 'without a secret' do
    let(:app_secret) { '' }

    it 'refuses before calling Meta' do
      expect { service.perform }.to raise_error(ArgumentError, 'App secret is required')
      expect(api_client).not_to have_received(:fetch_all_phone_numbers)
    end
  end

  it 'refuses a secret from another app' do
    allow(api_client).to receive(:app_secret_matches?).and_return(false)

    expect { service.perform }.to raise_error(ArgumentError, /App Secret does not belong/)
  end
end
