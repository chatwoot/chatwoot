require 'rails_helper'

RSpec.describe UserSessionTrackingService do
  let(:user) { create(:user) }
  let(:client_id) { 'client-abc' }
  let(:request) do
    instance_double(
      ActionDispatch::Request,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15',
      remote_ip: '8.8.8.8'
    )
  end
  let(:service) { described_class.new(user: user, request: request, client_id: client_id) }

  before do
    allow_any_instance_of(IpLookupService).to receive(:perform).and_return(
      double('GeocoderResult', city: 'Mountain View', country: 'United States', country_code: 'US')
    )
  end

  describe '#create_or_update!' do
    it 'creates a new UserSession with parsed metadata' do
      expect { service.create_or_update! }.to change(user.user_sessions, :count).by(1)

      session = user.user_sessions.last
      expect(session.client_id).to eq(client_id)
      expect(session.ip_address).to eq('8.8.8.8')
      expect(session.browser_name).to eq('Safari')
      expect(session.platform_name).to eq('macOS')
      expect(session.city).to eq('Mountain View')
      expect(session.country).to eq('United States')
      expect(session.country_code).to eq('US')
      expect(session.last_activity_at).to be_within(1.second).of(Time.current)
    end

    it 'updates an existing session when client_id matches' do
      existing = user.user_sessions.create!(client_id: client_id, ip_address: '1.1.1.1', last_activity_at: 1.day.ago)

      expect { service.create_or_update! }.not_to change(user.user_sessions, :count)
      expect(existing.reload.ip_address).to eq('8.8.8.8')
      expect(existing.last_activity_at).to be_within(1.second).of(Time.current)
    end

    it 'handles missing geo data gracefully' do
      allow_any_instance_of(IpLookupService).to receive(:perform).and_return(nil)

      service.create_or_update!

      session = user.user_sessions.last
      expect(session.city).to be_nil
      expect(session.country).to be_nil
      expect(session.country_code).to be_nil
    end
  end

  describe '#update_activity!' do
    it 'does nothing when no session exists for the client_id' do
      expect { service.update_activity! }.not_to change(user.user_sessions, :count)
    end

    it 'does nothing when the session was recently active' do
      session = user.user_sessions.create!(client_id: client_id, last_activity_at: 1.minute.ago)
      before_ts = session.last_activity_at

      service.update_activity!

      expect(session.reload.last_activity_at).to be_within(1.second).of(before_ts)
    end

    it 'bumps last_activity_at when the session is stale' do
      session = user.user_sessions.create!(client_id: client_id, last_activity_at: 10.minutes.ago)

      service.update_activity!

      expect(session.reload.last_activity_at).to be_within(1.second).of(Time.current)
    end

    it 'bumps last_activity_at when last_activity_at is nil' do
      session = user.user_sessions.create!(client_id: client_id, last_activity_at: nil)

      service.update_activity!

      expect(session.reload.last_activity_at).to be_within(1.second).of(Time.current)
    end
  end
end
