require 'rails_helper'

RSpec.describe Instagram::UnifiedLoginService do
  subject(:service) { described_class.new(access_token: 'system_user_token') }

  let(:base_url) { 'https://graph.facebook.com/v22.0' }
  let(:headers) { { 'Authorization' => 'Bearer system_user_token' } }

  before { allow(Chatwoot).to receive(:encryption_configured?).and_return(true) }

  it 'exchanges a code using the Meta app credentials without an Instagram token exchange' do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_UNIFIED_APP_ID', nil).and_return('meta_app')
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_UNIFIED_APP_SECRET', nil).and_return('meta_secret')
    request = stub_request(:get, "#{base_url}/oauth/access_token")
              .with(query: { client_id: 'meta_app', client_secret: 'meta_secret', code: 'code',
                             redirect_uri: 'https://example.com/instagram/callback' })
              .to_return(body: { access_token: 'system_user_token', token_type: 'bearer' }.to_json)

    result = described_class.new.exchange_code('code', 'https://example.com/instagram/callback')

    expect(result.fetch('access_token')).to eq('system_user_token')
    expect(result).not_to have_key('expires_in')
    expect(request).to have_been_requested.once
  end

  it 'rejects missing Meta app credentials' do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_UNIFIED_APP_ID', nil).and_return('meta_app')
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_UNIFIED_APP_SECRET', nil).and_return(nil)

    expect { described_class.credentials }.to raise_error(described_class::Error, I18n.t('instagram.missing_credentials'))
  end

  it 'requires encryption before exchanging provider credentials' do
    allow(Chatwoot).to receive(:encryption_configured?).and_return(false)

    expect { described_class.credentials }.to raise_error(described_class::Error, I18n.t('instagram.encryption_required'))
  end

  it 'discovers Instagram accounts across pages without using the system user as the Instagram ID' do
    stub_request(:get, "#{base_url}/me/assigned_instagram_accounts")
      .with(headers: headers, query: { fields: 'id,username', limit: 100 })
      .to_return(body: { data: [{ id: 'ig1', username: 'first' }], paging: { next: 'next_page', cursors: { after: 'cursor' } } }.to_json)
    stub_request(:get, "#{base_url}/me/assigned_instagram_accounts")
      .with(headers: headers, query: { fields: 'id,username', limit: 100, after: 'cursor' })
      .to_return(body: { data: [{ id: 'ig2', username: 'second' }] }.to_json)

    expect(service.accounts).to eq([{ 'id' => 'ig1', 'username' => 'first' }, { 'id' => 'ig2', 'username' => 'second' }])
  end

  it 'subscribes the Instagram account to messaging events' do
    request = stub_request(:post, "#{base_url}/ig1/subscribed_apps")
              .with(headers: headers, query: { subscribed_fields: 'messages,message_reactions,messaging_seen' })
              .to_return(body: { success: true }.to_json)

    expect(service.subscribe('ig1')).to eq('success' => true)
    expect(request).to have_been_requested.once
  end

  it 'surfaces a subscription failure' do
    stub_request(:post, "#{base_url}/ig1/subscribed_apps")
      .with(headers: headers, query: { subscribed_fields: 'messages,message_reactions,messaging_seen' })
      .to_return(status: 403, body: { error: { message: 'Missing messaging permission' } }.to_json)

    expect { service.subscribe('ig1') }.to raise_error(described_class::Error, 'Missing messaging permission')
  end

  it 'rejects an unsuccessful subscription even when Meta returns HTTP 200' do
    stub_request(:post, "#{base_url}/ig1/subscribed_apps")
      .with(headers: headers, query: { subscribed_fields: 'messages,message_reactions,messaging_seen' })
      .to_return(body: { success: false }.to_json)

    expect { service.subscribe('ig1') }.to raise_error(described_class::Error, I18n.t('instagram.subscription_failed'))
  end
end
