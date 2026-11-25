require 'rails_helper'

describe Whatsapp::ManualSetupService do
  let(:account) { create(:account) }
  let(:validation) { instance_double(Whatsapp::ManualSetupValidationService) }
  let(:webhook_setup) { instance_double(Whatsapp::WebhookSetupService, perform: nil, registration_error: nil) }

  before do
    allow(Whatsapp::ManualSetupValidationService).to receive(:new)
      .with(waba_id: 'waba', phone_number_id: 'phone-id', access_token: 'token', app_secret: 'customer_secret').and_return(validation)
    allow(validation).to receive(:perform).and_return(
      display_phone_number: '+5511988887777', phone_number_id: 'phone-id', waba_id: 'waba', suggested_inbox_name: 'Acme'
    )
    allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_setup)
    stub_request(:get, /graph\.facebook\.com/).to_return(status: 200, body: { data: [{ id: 'phone-id' }] }.to_json,
                                                         headers: { 'Content-Type' => 'application/json' })
  end

  # The secret is what verifies the inbox's webhooks; an inbox saved without it takes none.
  it 'keeps the app secret it validated on the inbox it creates' do
    setup = described_class.new(account: account, waba_id: 'waba', phone_number_id: 'phone-id', access_token: 'token',
                                app_secret: 'customer_secret').perform

    expect(setup.channel.reload.provider_config).to include('app_secret' => 'customer_secret', 'source' => 'manual_setup_v2')
  end
end
