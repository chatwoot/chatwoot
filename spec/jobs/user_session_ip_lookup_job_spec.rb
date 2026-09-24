require 'rails_helper'

RSpec.describe UserSessionIpLookupJob do
  let(:user) { create(:user) }
  let(:session) { user.user_sessions.create!(client_id: 'c', ip_address: '8.8.8.8', last_activity_at: Time.current) }
  let(:geo_result) { OpenStruct.new(city: 'Mountain View', country: 'United States', country_code: 'US') }
  let(:ip_lookup) { instance_double(IpLookupService) }

  before { allow(IpLookupService).to receive(:new).and_return(ip_lookup) }

  it 'backfills geo data on the session' do
    allow(ip_lookup).to receive(:perform).with('8.8.8.8').and_return(geo_result)

    described_class.perform_now(session)

    session.reload
    expect(session.city).to eq('Mountain View')
    expect(session.country).to eq('United States')
    expect(session.country_code).to eq('US')
  end

  it 'is a no-op when ip_address is blank' do
    session.update_columns(ip_address: nil) # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now(session)

    expect(IpLookupService).not_to have_received(:new)
  end

  it 'leaves the session untouched when lookup returns nil' do
    allow(ip_lookup).to receive(:perform).and_return(nil)

    described_class.perform_now(session)

    session.reload
    expect(session.city).to be_nil
    expect(session.country).to be_nil
  end

  it 'swallows lookup errors so a flaky geocoder does not poison the queue' do
    allow(ip_lookup).to receive(:perform).and_raise(StandardError.new('boom'))

    expect { described_class.perform_now(session) }.not_to raise_error
  end
end
