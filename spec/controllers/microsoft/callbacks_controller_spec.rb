require 'rails_helper'

RSpec.describe 'Microsoft::CallbacksController', type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:email) { Faker::Internet.email }
  let(:state) { account.to_sgid(expires_in: 15.minutes).to_s }
  let(:tenant_guid) { 'a1b2c3d4-1111-2222-3333-444455556666' }

  def token_body
    {
      'code' => code, 'grant_type' => 'authorization_code',
      'redirect_uri' => "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback",
      'scope' => Microsoft::Scopes::IMAP
    }
  end

  def create_account_app(tenant_id: nil)
    account.email_oauth_apps.create!(
      provider: 'microsoft', client_id: SecureRandom.uuid, client_secret: SecureRandom.hex(20),
      tenant_id: tenant_id
    )
  end

  describe 'GET /microsoft/callback' do
    let(:response_body_success) do
      { id_token: JWT.encode({ email: email, name: 'test' }, nil, 'none'), access_token: SecureRandom.hex(10), token_type: 'Bearer',
        refresh_token: SecureRandom.hex(10) }
    end

    let(:response_body_success_without_name) do
      { id_token: JWT.encode({ email: email }, nil, 'none'), access_token: SecureRandom.hex(10), token_type: 'Bearer',
        refresh_token: SecureRandom.hex(10) }
    end

    it 'creates inboxes if authentication is successful' do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: token_body)
        .to_return(status: 200, body: response_body_success.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code, state: state }

      expect(response).to redirect_to app_email_inbox_agents_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      inbox = account.inboxes.last
      expect(inbox.name).to eq 'test'
      expect(inbox.channel.reload.provider_config.keys).to include('access_token', 'refresh_token', 'expires_on')
      expect(inbox.channel.reload.provider_config['access_token']).to eq response_body_success[:access_token]
      expect(inbox.channel.imap_address).to eq 'outlook.office365.com'
    end

    it 'exchanges the code on the tenant-specific endpoint when the account app has a tenant_id' do
      create_account_app(tenant_id: tenant_guid)
      tenant_token_request = stub_request(:post, "https://login.microsoftonline.com/#{tenant_guid}/oauth2/v2.0/token")
                             .with(body: token_body)
                             .to_return(status: 200, body: response_body_success.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code, state: state }

      expect(tenant_token_request).to have_been_requested
      expect(account.inboxes.count).to be 1
    end

    it 'sets imap_login from preferred_username when the id_token carries a UPN that differs from email' do
      upn = 'testaccount@primary-domain.example'
      mailbox = 'TestAccount@mailbox-domain.example'
      response_body = {
        id_token: JWT.encode({ email: mailbox, preferred_username: upn, name: 'test' }, nil, 'none'),
        access_token: SecureRandom.hex(10), token_type: 'Bearer', refresh_token: SecureRandom.hex(10)
      }
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: token_body)
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code, state: state }

      channel = account.inboxes.last.channel
      expect(channel.imap_login).to eq upn
      expect(channel.email).to eq mailbox
    end

    it 'creates updates inbox channel config if inbox exists and authentication is successful' do
      inbox = create(:channel_email, account: account, email: email)&.inbox
      expect(inbox.channel.provider_config).to eq({})

      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: token_body)
        .to_return(status: 200, body: response_body_success.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code, state: state }

      expect(response).to redirect_to app_email_inbox_settings_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      expect(inbox.channel.reload.provider_config.keys).to include('access_token', 'refresh_token', 'expires_on')
      expect(inbox.channel.reload.provider_config['access_token']).to eq response_body_success[:access_token]
      expect(inbox.channel.imap_address).to eq 'outlook.office365.com'
    end

    it 'creates inboxes with fallback_name when account name is not present in id_token' do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: token_body)
        .to_return(status: 200, body: response_body_success_without_name.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code, state: state }

      expect(response).to redirect_to app_email_inbox_agents_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      inbox = account.inboxes.last
      expect(inbox.name).to eq email.split('@').first.parameterize.titleize
    end

    context 'when the provider returns an error instead of a code' do
      it 'skips the token exchange and surfaces the AADSTS code on the inbox settings page' do
        get microsoft_callback_url, params: {
          error: 'invalid_request',
          error_description: "AADSTS50194: Application 'x' is not configured as a multi-tenant application.",
          state: state
        }

        expect(response).to redirect_to("/app/accounts/#{account.id}/settings/inboxes/new?oauth_error=AADSTS50194")
        expect(a_request(:post, /login\.microsoftonline\.com/)).not_to have_been_made
      end

      it 'surfaces missing_code when the callback arrives without code or error' do
        get microsoft_callback_url, params: { state: state }

        expect(response).to redirect_to("/app/accounts/#{account.id}/settings/inboxes/new?oauth_error=missing_code")
      end

      it 'falls back to the home page when the state does not resolve an account' do
        get microsoft_callback_url, params: { error: 'access_denied', state: 'garbage' }

        expect(response).to redirect_to '/'
      end
    end

    it 'redirects to the inbox settings page with an error code when the token exchange fails' do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: token_body)
        .to_return(status: 401)

      get microsoft_callback_url, params: { code: code, state: state }

      expect(response).to redirect_to("/app/accounts/#{account.id}/settings/inboxes/new?oauth_error=token_exchange_failed")
    end
  end
end
