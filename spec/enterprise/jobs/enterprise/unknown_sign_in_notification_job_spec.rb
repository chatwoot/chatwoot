require 'rails_helper'

RSpec.describe Enterprise::UnknownSignInNotificationJob do
  geo_result = Struct.new(:city, :country)

  let(:device) { { ip: '203.0.113.7', browser_name: 'Chrome', platform_name: 'macOS' } }

  before do
    create(:installation_config, name: 'UNKNOWN_SIGNIN_NOTIFICATION_ENABLED', value: true)
    GlobalConfig.clear_cache
  end

  it 'sends the alert with resolved location context' do
    lookup = instance_double(IpLookupService)
    allow(IpLookupService).to receive(:new).and_return(lookup)
    allow(lookup).to receive(:perform).with('203.0.113.7').and_return(geo_result.new('Northtown', 'Northland'))

    expect do
      described_class.perform_now('agent@example.com', device)
    end.to have_enqueued_mail(Enterprise::UnknownSignInMailer, :unknown_sign_in).with(
      hash_including(email: 'agent@example.com', city: 'Northtown', country: 'Northland', browser_name: 'Chrome')
    )
  end

  it 'still sends when the IP cannot be geolocated' do
    lookup = instance_double(IpLookupService, perform: nil)
    allow(IpLookupService).to receive(:new).and_return(lookup)

    expect do
      described_class.perform_now('agent@example.com', device)
    end.to have_enqueued_mail(Enterprise::UnknownSignInMailer, :unknown_sign_in).with(
      hash_including(email: 'agent@example.com', city: nil, country: nil)
    )
  end

  it 'does not send when the feature is disabled' do
    InstallationConfig.find_by(name: 'UNKNOWN_SIGNIN_NOTIFICATION_ENABLED').update!(value: false)
    GlobalConfig.clear_cache
    expect do
      described_class.perform_now('agent@example.com', device)
    end.not_to have_enqueued_mail(Enterprise::UnknownSignInMailer, :unknown_sign_in)
  end

  it 'does not send without a recipient' do
    expect do
      described_class.perform_now('', device)
    end.not_to have_enqueued_mail(Enterprise::UnknownSignInMailer, :unknown_sign_in)
  end
end
