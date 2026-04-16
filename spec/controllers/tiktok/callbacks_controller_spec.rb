require 'rails_helper'

RSpec.describe 'TikTok Callbacks', type: :request do
  let(:account) { create(:account) }

  let(:client_secret) { 'tiktok-app-secret' }
  let(:client_id) { 'tiktok-app-id' }

  let(:token_endpoint) { 'https://business-api.tiktok.com/open_api/v1.3/tt_user/oauth2/token/' }
  let(:business_endpoint) { 'https://business-api.tiktok.com/open_api/v1.3/business/get/' }

  let(:tiktok_access_token) { 'access-token-1' }
  let(:tiktok_refresh_token) { 'refresh-token-1' }
  let(:tiktok_business_id) { 'biz-123' }

  let(:token_response) do
    {
      code: 0,
      message: 'ok',
      data: {
        open_id: tiktok_business_id,
        scope: Tiktok::AuthClient::REQUIRED_SCOPES.join(','),
        access_token: tiktok_access_token,
        refresh_token: tiktok_refresh_token,
        expires_in: 86_400,
        refresh_token_expires_in: 2_592_000
      }
    }.to_json
  end

  let(:business_response) do
    {
      code: 0,
      message: 'ok',
      data: {
        username: 'tiktok_user',
        display_name: 'TikTok Display Name',
        profile_image: 'https://www.example.com/avatar.png'
      }
    }.to_json
  end

  let(:state) do
    JWT.encode({ sub: account.id, iat: Time.current.to_i }, client_secret, 'HS256')
  end

  before do
    InstallationConfig.where(name: %w[TIKTOK_APP_ID TIKTOK_APP_SECRET]).delete_all
    GlobalConfig.clear_cache

    stub_request(:post, token_endpoint).to_return(status: 200, body: token_response, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, business_endpoint)
      .with(query: hash_including('business_id' => tiktok_business_id))
      .to_return(status: 200, body: business_response, headers: { 'Content-Type' => 'application/json' })
  end

  it 'creates channel and inbox and redirects to agents step for new connections' do
    expect(Avatar::AvatarFromUrlJob).to receive(:perform_later).with(instance_of(Inbox), 'https://www.example.com/avatar.png')

    with_modified_env TIKTOK_APP_ID: client_id, TIKTOK_APP_SECRET: client_secret do
      expect do
        get '/tiktok/callback', params: { code: 'valid_code', state: state }
      end.to change(Channel::Tiktok, :count).by(1).and change(Inbox, :count).by(1)
    end

    inbox = Inbox.last
    channel = inbox.channel

    expect(channel.business_id).to eq(tiktok_business_id)
    expect(channel.access_token).to eq(tiktok_access_token)
    expect(channel.refresh_token).to eq(tiktok_refresh_token)

    expect(response).to redirect_to(app_tiktok_inbox_agents_url(account_id: account.id, inbox_id: inbox.id))
  end

  it 'updates an existing channel and redirects to settings' do
    existing_channel = create(
      :channel_tiktok,
      account: account,
      business_id: tiktok_business_id,
      access_token: 'old-access-token',
      refresh_token: 'old-refresh-token',
      expires_at: 1.hour.ago,
      refresh_token_expires_at: 1.day.from_now
    )
    existing_channel.inbox.update!(name: 'Old Name')

    with_modified_env TIKTOK_APP_ID: client_id, TIKTOK_APP_SECRET: client_secret do
      expect do
        get '/tiktok/callback', params: { code: 'valid_code', state: state }
      end.to not_change(Channel::Tiktok, :count).and not_change(Inbox, :count)
    end

    existing_channel.reload
    inbox = existing_channel.inbox.reload

    expect(existing_channel.access_token).to eq(tiktok_access_token)
    expect(existing_channel.refresh_token).to eq(tiktok_refresh_token)
    expect(inbox.name).to eq('TikTok Display Name')

    expect(response).to redirect_to(app_tiktok_inbox_settings_url(account_id: account.id, inbox_id: inbox.id))
  end

  it 'redirects to error page when user denies authorization' do
    with_modified_env TIKTOK_APP_ID: client_id, TIKTOK_APP_SECRET: client_secret do
      get '/tiktok/callback', params: { error: 'access_denied', error_description: 'User cancelled', error_code: '400', state: state }
    end

    expect(response).to redirect_to(
      app_new_tiktok_inbox_url(
        account_id: account.id,
        error_type: 'access_denied',
        code: '400',
        error_message: 'User cancelled'
      )
    )
  end

  it 'redirects to error page when required scopes are not granted' do
    stub_request(:post, token_endpoint).to_return(
      status: 200,
      body: JSON.parse(token_response).deep_merge('data' => { 'scope' => 'user.info.basic' }).to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    with_modified_env TIKTOK_APP_ID: client_id, TIKTOK_APP_SECRET: client_secret do
      get '/tiktok/callback', params: { code: 'valid_code', state: state }
    end

    expect(response).to redirect_to(
      app_new_tiktok_inbox_url(
        account_id: account.id,
        error_type: 'ungranted_scopes',
        code: 400,
        error_message: 'User did not grant all the required scopes'
      )
    )
  end
end
