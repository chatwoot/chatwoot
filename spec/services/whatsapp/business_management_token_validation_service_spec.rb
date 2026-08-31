require 'rails_helper'

RSpec.describe Whatsapp::BusinessManagementTokenValidationService do
  let(:permissions_url) { 'https://graph.facebook.com/v22.0/me/permissions' }
  let(:templates_url) { 'https://graph.facebook.com/v22.0/waba-id/message_templates?limit=1' }
  let(:service) { described_class.new('business-token', 'waba-id') }

  around do |example|
    with_modified_env WHATSAPP_CLOUD_BASE_URL: 'https://graph.facebook.com' do
      example.run
    end
  end

  before do
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return('v22.0')
  end

  it 'accepts a token with the WhatsApp business management permission' do
    stub_request(:get, permissions_url)
      .with(headers: { 'Authorization' => 'Bearer business-token' })
      .to_return(
        status: 200,
        body: {
          data: [
            { permission: 'whatsapp_business_management', status: 'granted' },
            { permission: 'whatsapp_business_messaging', status: 'granted' }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    stub_request(:get, templates_url)
      .with(headers: { 'Authorization' => 'Bearer business-token' })
      .to_return(status: 200, body: { data: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(service.perform).to be(true)
  end

  it 'rejects a token without the WhatsApp business management permission' do
    stub_request(:get, permissions_url)
      .with(headers: { 'Authorization' => 'Bearer business-token' })
      .to_return(
        status: 200,
        body: {
          data: [
            { permission: 'whatsapp_business_management', status: 'declined' },
            { permission: 'whatsapp_business_messaging', status: 'granted' }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect { service.perform }
      .to raise_error(ArgumentError, 'Business management token must grant the whatsapp_business_management permission')
  end

  it 'rejects malformed permission entries as a controlled validation error' do
    stub_request(:get, permissions_url)
      .to_return(
        status: 200,
        body: { data: [nil, 'invalid'] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect { service.perform }
      .to raise_error(ArgumentError, 'Business management token must grant the whatsapp_business_management permission')
  end

  it 'rejects a token without access to the inbox WhatsApp Business Account' do
    stub_request(:get, permissions_url)
      .to_return(
        status: 200,
        body: { data: [{ permission: 'whatsapp_business_management', status: 'granted' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    stub_request(:get, templates_url)
      .with(headers: { 'Authorization' => 'Bearer business-token' })
      .to_return(
        status: 403,
        body: { error: { message: 'Permission denied' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect { service.perform }.to raise_error(ArgumentError, 'Permission denied')
  end

  it 'returns the provider error when the permission check fails' do
    stub_request(:get, permissions_url)
      .with(headers: { 'Authorization' => 'Bearer business-token' })
      .to_return(
        status: 403,
        body: { error: { message: 'Permission denied' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect { service.perform }
      .to raise_error(ArgumentError, 'Permission denied')
  end

  it 'returns a safe error when the permission request times out' do
    stub_request(:get, permissions_url).to_timeout

    expect { service.perform }
      .to raise_error(ArgumentError, 'Could not validate business management token permissions. Please try again.')
  end
end
