require 'rails_helper'

RSpec.describe Whatsapp::BusinessProfileService do
  subject(:service) { described_class.new(channel, api_version: 'v24.0') }

  let(:channel) do
    instance_double(
      Channel::Whatsapp,
      provider_config: {
        'api_key' => 'test_access_token',
        'phone_number_id' => 'test_phone_number_id'
      }
    )
  end
  let(:profile_response) do
    {
      'data' => [
        {
          'about' => 'Support that feels personal',
          'profile_picture_url' => 'https://example.com/profile.png',
          'websites' => ['https://example.com', 'https://docs.example.com']
        }
      ]
    }
  end

  before do
    allow(Rails.logger).to receive(:warn)
  end

  it 'returns the business profile from the phone number endpoint' do
    request = stub_request(
      :get,
      %r{\Ahttps://graph\.facebook\.com/v24\.0/test_phone_number_id/whatsapp_business_profile\?}
    ).to_return(status: 200, body: profile_response.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(service.fetch).to eq(profile_response['data'].first)
    expect(request).to have_been_requested.once
  end

  it 'handles an unexpected error payload without hiding the HTTP failure' do
    stub_request(:get, %r{/test_phone_number_id/whatsapp_business_profile})
      .to_return(status: 500, body: { error: 'unexpected response' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(service.fetch).to be_nil
    expect(Rails.logger).to have_received(:warn).with(
      '[WHATSAPP HEALTH] Business profile unavailable: http_status=500 code= subcode= message='
    )
  end

  it 'logs the phone number identifier when the profile request raises' do
    stub_request(:get, %r{/test_phone_number_id/whatsapp_business_profile}).to_raise(Timeout::Error)

    expect(service.fetch).to be_nil
    expect(Rails.logger).to have_received(:warn).with(
      '[WHATSAPP HEALTH] Business profile unavailable: phone_number_id=test_phone_number_id error_class=Timeout::Error'
    )
  end
end
