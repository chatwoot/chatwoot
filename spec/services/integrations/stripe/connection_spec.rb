require 'rails_helper'

RSpec.describe Integrations::Stripe::Connection do
  let(:credentials) { { access_token: 'existing-access', refresh_token: 'existing-refresh', expires_at: 30.minutes.from_now.to_i } }
  let(:hook) { create(:integrations_hook, app_id: 'stripe', access_token: credentials.to_json) }
  let(:connection) { described_class.new(hook) }

  before do
    allow(GlobalConfig).to receive(:get_value).and_call_original
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return('sk_test_app')
  end

  it 'reuses a valid token without calling Stripe' do
    expect(connection.api_token).to eq('existing-access')
    expect(WebMock).not_to have_requested(:post, 'https://api.stripe.com/v1/oauth/token')
  end

  it 'refreshes an expiring token and persists the rotated refresh token' do
    hook.update!(access_token: credentials.merge(expires_at: 30.seconds.from_now.to_i).to_json)
    request = stub_request(:post, 'https://api.stripe.com/v1/oauth/token')
              .with(body: hash_including('grant_type' => 'refresh_token', 'refresh_token' => 'existing-refresh'))
              .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                         body: { access_token: 'new-access', refresh_token: 'new-refresh', token_type: 'bearer' }.to_json)
    expect(connection.api_token).to eq('new-access')
    expect(JSON.parse(hook.reload.access_token)).to include('refresh_token' => 'new-refresh')
    expect(connection.api_token).to eq('new-access')
    expect(request).to have_been_requested.once
  end

  it 'preserves credentials when refresh fails' do
    hook.update!(access_token: credentials.merge(expires_at: 1.minute.ago.to_i).to_json)
    original = hook.access_token
    stub_request(:post, 'https://api.stripe.com/v1/oauth/token').to_return(status: 400, body: '{"error":"invalid_grant"}')
    expect { connection.api_token }.to raise_error(OAuth2::Error)
    expect(hook.reload.access_token).to eq(original)
  end

  it 'refreshes live connections using the live developer key and preserves their environment' do
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return('sk_live_app')
    hook.update!(settings: { 'livemode' => true }, access_token: credentials.merge(expires_at: 1.minute.ago.to_i).to_json)
    request = stub_request(:post, 'https://api.stripe.com/v1/oauth/token')
              .with(basic_auth: ['sk_live_app', ''])
              .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                         body: { access_token: 'live-access', refresh_token: 'live-refresh', token_type: 'bearer' }.to_json)
    expect(connection.api_token).to eq('live-access')
    expect(hook.reload.settings).to include('livemode' => true)
    expect(request).to have_been_requested.once
  end

  it 'does not refresh legacy sandbox connections using a live key' do
    allow(GlobalConfig).to receive(:get_value).with('STRIPE_APP_SECRET_KEY').and_return('sk_live_app')
    hook.update!(access_token: credentials.merge(expires_at: 1.minute.ago.to_i).to_json)
    expect { connection.api_token }.to raise_error(ArgumentError, /environment/)
    expect(WebMock).not_to have_requested(:post, 'https://api.stripe.com/v1/oauth/token')
    expect(JSON.parse(hook.reload.access_token)).to include('refresh_token' => 'existing-refresh')
  end

  it 'encrypts both tokens at rest' do
    skip 'Encryption keys are required for this check' unless Chatwoot.encryption_configured?
    expect(hook.reload.access_token_before_type_cast).not_to include('existing-access', 'existing-refresh')
    expect(JSON.parse(hook.access_token)).to include('access_token' => 'existing-access', 'refresh_token' => 'existing-refresh')
  end
end
