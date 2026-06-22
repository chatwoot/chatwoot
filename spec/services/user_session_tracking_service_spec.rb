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

  describe '#create_or_update!' do
    it 'creates a new UserSession with the right client_id and timestamps' do
      expect { service.create_or_update! }.to change(user.user_sessions, :count).by(1)

      session = user.user_sessions.last
      expect(session.client_id).to eq(client_id)
      expect(session.last_activity_at).to be_within(1.second).of(Time.current)
    end

    it 'populates request and browser metadata synchronously', :aggregate_failures do
      service.create_or_update!

      session = user.user_sessions.last
      expect(session.ip_address).to eq('8.8.8.8')
      expect(session.browser_name).to eq('Safari')
      expect(session.platform_name).to eq('macOS')
    end

    it 'does not call IpLookupService synchronously' do
      expect(IpLookupService).not_to receive(:new)

      service.create_or_update!
    end

    it 'enqueues UserSessionIpLookupJob to backfill geo data' do
      expect { service.create_or_update! }.to have_enqueued_job(UserSessionIpLookupJob)
    end

    it 'updates an existing session when client_id matches' do
      existing = user.user_sessions.create!(client_id: client_id, ip_address: '1.1.1.1', last_activity_at: 1.day.ago)

      expect { service.create_or_update! }.not_to change(user.user_sessions, :count)
      expect(existing.reload.ip_address).to eq('8.8.8.8')
      expect(existing.last_activity_at).to be_within(1.second).of(Time.current)
    end

    context 'with a Chatwoot Mobile legacy User-Agent' do
      let(:request) do
        instance_double(
          ActionDispatch::Request,
          user_agent: ua,
          remote_ip: '8.8.8.8'
        )
      end

      context 'when the UA is okhttp (Android Chatwoot Mobile)' do
        let(:ua) { 'okhttp/4.9.2' }

        it 'labels the session as Chatwoot Mobile on Android', :aggregate_failures do
          service.create_or_update!

          session = user.user_sessions.last
          expect(session.browser_name).to eq('Chatwoot Mobile')
          expect(session.browser_version).to be_nil
          expect(session.platform_name).to eq('Android')
          expect(session.platform_version).to be_nil
          expect(session.device_name).to eq('Android')
          expect(session.user_agent).to eq(ua)
        end
      end

      context 'when the UA is CFNetwork (iOS Chatwoot Mobile)' do
        let(:ua) { 'Chatwoot/3759 CFNetwork/3886.100.1 Darwin/27.0.0' }

        it 'labels the session as Chatwoot Mobile on iPhone', :aggregate_failures do
          service.create_or_update!

          session = user.user_sessions.last
          expect(session.browser_name).to eq('Chatwoot Mobile')
          expect(session.browser_version).to be_nil
          expect(session.platform_name).to eq('iPhone')
          expect(session.platform_version).to be_nil
          expect(session.device_name).to eq('iPhone')
          expect(session.user_agent).to eq(ua)
        end
      end

      context 'when the UA is a real browser (Firefox on Linux)' do
        let(:ua) { 'Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0' }

        it 'does not override the Browser-derived metadata', :aggregate_failures do
          service.create_or_update!

          session = user.user_sessions.last
          expect(session.browser_name).to eq('Firefox')
          expect(session.platform_name).to eq('Generic Linux')
          expect(session.device_name).not_to eq('Android')
          expect(session.device_name).not_to eq('iPhone')
        end
      end

      context 'when the UA is unknown but does not match any mobile pattern' do
        let(:ua) { 'curl/8.4.0' }

        it 'leaves the Unknown labels untouched', :aggregate_failures do
          service.create_or_update!

          session = user.user_sessions.last
          expect(session.browser_name).to eq('Unknown Browser')
          expect(session.platform_name).to eq('Unknown')
          expect(session.device_name).to eq('Unknown')
        end
      end
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
