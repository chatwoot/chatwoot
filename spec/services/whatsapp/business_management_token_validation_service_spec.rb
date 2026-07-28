require 'rails_helper'

RSpec.describe Whatsapp::BusinessManagementTokenValidationService do
  let(:permissions_url) { 'https://graph.facebook.com/v22.0/me/permissions' }

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

    expect(described_class.new('business-token').perform).to be(true)
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

    expect { described_class.new('business-token').perform }
      .to raise_error(ArgumentError, 'Business management token must grant the whatsapp_business_management permission')
  end

  it 'returns the provider error when the permission check fails' do
    stub_request(:get, permissions_url)
      .with(headers: { 'Authorization' => 'Bearer business-token' })
      .to_return(
        status: 403,
        body: { error: { message: 'Permission denied' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect { described_class.new('business-token').perform }
      .to raise_error(ArgumentError, 'Permission denied')
  end
end
