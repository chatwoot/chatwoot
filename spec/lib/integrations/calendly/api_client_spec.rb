require 'rails_helper'

RSpec.describe Integrations::Calendly::ApiClient do
  let(:account) { create(:account) }
  let(:hook) do
    create(:integrations_hook,
           account: account,
           app_id: 'calendly',
           access_token: 'test-access-token',
           settings: {
             'calendly_user_uri' => 'https://api.calendly.com/users/ABC123',
             'calendly_organization_uri' => 'https://api.calendly.com/organizations/ORG123',
             'refresh_token' => 'test-refresh-token',
             'token_expires_at' => 3.hours.from_now.iso8601,
             'signing_key' => SecureRandom.hex(32)
           })
  end

  let(:client) { described_class.new(hook) }

  describe '#current_user' do
    it 'returns the current user resource' do
      stub_request(:get, 'https://api.calendly.com/users/me')
        .to_return(status: 200, body: { resource: { uri: 'https://api.calendly.com/users/ABC123', name: 'Test User' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = client.current_user
      expect(result['uri']).to eq('https://api.calendly.com/users/ABC123')
      expect(result['name']).to eq('Test User')
    end
  end

  describe '#list_event_types' do
    it 'returns event types collection' do
      stub_request(:get, 'https://api.calendly.com/event_types')
        .with(query: { user: 'https://api.calendly.com/users/ABC123', active: true })
        .to_return(status: 200, body: { collection: [{ name: '30min Meeting' }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = client.list_event_types
      expect(result).to be_an(Array)
      expect(result.first['name']).to eq('30min Meeting')
    end
  end

  describe '#create_scheduling_link' do
    it 'creates a scheduling link' do
      event_type_uri = 'https://api.calendly.com/event_types/ET123'
      stub_request(:post, 'https://api.calendly.com/scheduling_links')
        .to_return(status: 201, body: { resource: { booking_url: 'https://calendly.com/d/abc' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = client.create_scheduling_link(event_type_uri)
      expect(result['booking_url']).to eq('https://calendly.com/d/abc')
    end
  end

  describe '#list_scheduled_events' do
    it 'returns scheduled events' do
      stub_request(:get, 'https://api.calendly.com/scheduled_events')
        .with(query: hash_including(user: 'https://api.calendly.com/users/ABC123', status: 'active'))
        .to_return(status: 200, body: { collection: [{ name: 'Demo Call', status: 'active' }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = client.list_scheduled_events
      expect(result.first['name']).to eq('Demo Call')
    end
  end

  describe '#cancel_event' do
    it 'cancels an event' do
      stub_request(:post, 'https://api.calendly.com/scheduled_events/EV123/cancellation')
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { client.cancel_event('EV123', reason: 'Changed plans') }.not_to raise_error
    end
  end

  describe 'token refresh' do
    let(:hook_with_expired_token) do
      create(:integrations_hook,
             account: account,
             app_id: 'calendly',
             access_token: 'expired-token',
             settings: {
               'calendly_user_uri' => 'https://api.calendly.com/users/ABC123',
               'refresh_token' => 'test-refresh-token',
               'token_expires_at' => 1.hour.ago.iso8601,
               'signing_key' => SecureRandom.hex(32)
             })
    end

    let(:expired_client) { described_class.new(hook_with_expired_token) }

    before do
      allow(GlobalConfigService).to receive(:load).with('CALENDLY_CLIENT_ID', nil).and_return('test-client-id')
      allow(GlobalConfigService).to receive(:load).with('CALENDLY_CLIENT_SECRET', nil).and_return('test-client-secret')
    end

    it 'refreshes the token when expired' do
      stub_request(:post, 'https://auth.calendly.com/oauth/token')
        .to_return(status: 200, body: {
          access_token: 'new-access-token',
          refresh_token: 'new-refresh-token',
          expires_in: 7200
        }.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, 'https://api.calendly.com/users/me')
        .to_return(status: 200, body: { resource: { uri: 'https://api.calendly.com/users/ABC123' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expired_client.current_user
      hook_with_expired_token.reload
      expect(hook_with_expired_token.access_token).to eq('new-access-token')
    end

    it 'marks hook as unauthorized on refresh failure' do
      stub_request(:post, 'https://auth.calendly.com/oauth/token')
        .to_return(status: 401, body: { error: 'invalid_grant' }.to_json)

      expect { expired_client.current_user }.to raise_error(RuntimeError, /token refresh failed/)
    end
  end

  describe 'error handling' do
    it 'raises on 401 unauthorized' do
      stub_request(:get, 'https://api.calendly.com/users/me')
        .to_return(status: 401, body: { error: 'unauthorized' }.to_json)

      expect { client.current_user }.to raise_error(RuntimeError, /unauthorized/)
    end

    it 'raises on 429 rate limit' do
      stub_request(:get, 'https://api.calendly.com/users/me')
        .to_return(status: 429, body: '', headers: { 'Retry-After' => '30' })

      expect { client.current_user }.to raise_error(RuntimeError, /rate limited/)
    end
  end

  describe '.exchange_code' do
    before do
      allow(GlobalConfigService).to receive(:load).with('CALENDLY_CLIENT_ID', nil).and_return('test-client-id')
      allow(GlobalConfigService).to receive(:load).with('CALENDLY_CLIENT_SECRET', nil).and_return('test-client-secret')
    end

    it 'exchanges an authorization code for tokens' do
      stub_request(:post, 'https://auth.calendly.com/oauth/token')
        .to_return(status: 200, body: {
          access_token: 'new-token',
          refresh_token: 'new-refresh',
          expires_in: 7200
        }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = described_class.exchange_code('auth-code', 'http://localhost:3000/calendly/callback')
      expect(result['access_token']).to eq('new-token')
    end

    it 'raises on OAuth error' do
      stub_request(:post, 'https://auth.calendly.com/oauth/token')
        .to_return(status: 400, body: { error: 'invalid_grant' }.to_json)

      expect do
        described_class.exchange_code('bad-code', 'http://localhost:3000/calendly/callback')
      end.to raise_error(RuntimeError, /OAuth error/)
    end
  end
end
