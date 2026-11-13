require 'rails_helper'

RSpec.describe Instagram::CallbacksController do
  let(:account) { create(:account) }
  let(:valid_params) { { code: 'valid_code', state: "#{account.id}|valid_token" } }
  let(:error_params) { { error: 'access_denied', error_description: 'User denied access', state: "#{account.id}|valid_token" } }
  let(:oauth_client) { instance_double(OAuth2::Client) }
  let(:auth_code_object) { instance_double(OAuth2::Strategy::AuthCode) }
  let(:access_token) { instance_double(OAuth2::AccessToken, token: 'test_token') }
  let(:long_lived_token_response) { { 'access_token' => 'long_lived_test_token', 'expires_in' => 5_184_000 } }
  let(:user_details) { { 'username' => 'test_user', 'user_id' => '12345' } }
  let(:exception_tracker) { instance_double(ChatwootExceptionTracker) }

  before do
    allow(controller).to receive(:verify_instagram_token).and_return(account.id)
    allow(controller).to receive(:instagram_token_inbox_id).and_return(nil)
    allow(controller).to receive(:instagram_client).and_return(oauth_client)
    allow(controller).to receive(:base_url).and_return('https://app.chatwoot.com')
    allow(controller).to receive(:account).and_return(account)
    allow(oauth_client).to receive(:auth_code).and_return(auth_code_object)
    allow(controller).to receive(:exchange_for_long_lived_token).and_return(long_lived_token_response)
    allow(controller).to receive(:fetch_instagram_user_details).and_return(user_details)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
    allow(exception_tracker).to receive(:capture_exception)

    # Stub the exact request format that's being made
    stub_request(:post, 'https://graph.instagram.com/v22.0/12345/subscribed_apps?access_token=long_lived_test_token&subscribed_fields%5B%5D=messages&subscribed_fields%5B%5D=message_reactions&subscribed_fields%5B%5D=messaging_seen')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: '', headers: {})
  end

  describe '#show' do
    context 'with Unified Login state' do
      before do
        allow(Redis::SecureStorage).to receive(:ensure_encryption_configured!)
        allow(controller).to receive(:instagram_token_configuration_id).and_return('config1')
        allow(Instagram::UnifiedLoginService).to receive(:credentials).and_return(client_id: 'meta_app', client_secret: 'meta_secret')
        stub_request(:get, 'https://graph.facebook.com/v22.0/oauth/access_token')
          .with(query: hash_including(code: 'valid_code', redirect_uri: 'https://app.chatwoot.com/instagram/callback'))
          .to_return(body: { access_token: 'system_token' }.to_json)
        stub_request(:get, 'https://graph.facebook.com/v22.0/me/assigned_instagram_accounts')
          .with(query: { fields: 'id,username', limit: 100 }, headers: { 'Authorization' => 'Bearer system_token' })
          .to_return(body: { data: [{ id: '12345', username: 'test_user' }, { id: '67890', username: 'second_user' }] }.to_json)
      end

      it 'keeps credentials on the server and lets the administrator select an account' do
        expect { get :show, params: valid_params }.not_to change(Inbox, :count)
        location = URI(response.location)
        query = Rack::Utils.parse_query(location.query)
        expect(location.path).to eq("/app/accounts/#{account.id}/settings/inboxes/new/instagram")
        expect(query.fetch('connection_token')).to match(/\A[0-9a-f]{64}\z/)
        expect(response.location).not_to include('system_token')
        connection = Instagram::PendingConnection.new(account: account, token: query.fetch('connection_token'))
        expect(connection.accounts.pluck('id')).to eq(%w[12345 67890])
      end

      it 'only offers the original Instagram account when reconnecting' do
        channel = create(:channel_instagram, account: account, instagram_id: '12345')
        allow(controller).to receive(:instagram_token_inbox_id).and_return(channel.inbox.id)
        expect { get :show, params: valid_params }.not_to change(Inbox, :count)
        query = Rack::Utils.parse_query(URI(response.location).query)
        connection = Instagram::PendingConnection.new(account: account, token: query.fetch('connection_token'))
        expect(connection.accounts.pluck('id')).to eq(['12345'])
      end

      it 'rejects a different Instagram account when reconnecting without creating an inbox' do
        channel = create(:channel_instagram, account: account, instagram_id: 'original')
        allow(controller).to receive(:instagram_token_inbox_id).and_return(channel.inbox.id)
        expect { get :show, params: valid_params }.not_to change(Inbox, :count)
        query = Rack::Utils.parse_query(URI(response.location).query)
        expect(query['error_message']).to eq(I18n.t('instagram.wrong_account'))
        expect(query['error_type']).to eq('Instagram::ConnectionError')
        expect(channel.reload[:access_token]).not_to eq('system_token')
      end
    end

    context 'with expired signed state' do
      before do
        allow(controller).to receive(:verify_instagram_token).and_call_original
        allow(controller).to receive(:client_secret).and_return('state_secret')
      end

      it 'redirects an expired legacy connection to the retry page without exchanging its code' do
        state = JWT.encode({ sub: account.id, exp: 1.minute.ago.to_i }, 'state_secret', 'HS256')
        expect(auth_code_object).not_to receive(:get_token)
        get :show, params: { code: 'valid_code', state: state }
        expected_url = app_new_instagram_inbox_url(
          account_id: account.id, error_type: 'authorization_expired', code: 400,
          error_message: I18n.t('instagram.authorization_expired')
        )
        expect(response).to redirect_to(expected_url)
      end

      it 'does not use the account ID from a state with an invalid signature' do
        state = JWT.encode({ sub: account.id, exp: 1.minute.ago.to_i }, 'wrong_secret', 'HS256')
        expect(auth_code_object).not_to receive(:get_token)
        get :show, params: { code: 'valid_code', state: state }
        expect(response).to have_http_status(:bad_request)
      end

      it 'does not exchange an expired Unified Login code' do
        state = JWT.encode({ sub: account.id, exp: 1.minute.ago.to_i, configuration_id: 'config1' }, 'state_secret', 'HS256')
        expect(Instagram::UnifiedLoginService).not_to receive(:new)
        get :show, params: { code: 'valid_code', state: state }
        expect(response).to have_http_status(:redirect)
        expect(Rack::Utils.parse_query(URI(response.location).query)['error_message']).to eq(I18n.t('instagram.authorization_expired'))
      end
    end

    it 'rejects invalid state before exchanging an authorization code' do
      allow(controller).to receive(:verify_instagram_token).and_return(nil)
      expect(auth_code_object).not_to receive(:get_token)
      get :show, params: valid_params
      expect(response).to have_http_status(:bad_request)
    end

    context 'when authorization is successful' do
      before do
        allow(auth_code_object).to receive(:get_token).and_return(access_token)
      end

      it 'rejects the wrong account when reconnecting through Instagram Login' do
        channel = create(:channel_instagram, account: account, instagram_id: 'original')
        old_token = channel[:access_token]
        allow(controller).to receive(:instagram_token_inbox_id).and_return(channel.inbox.id)
        expect { get :show, params: valid_params }.not_to change(Inbox, :count)
        expect(channel.reload[:access_token]).to eq(old_token)
        expect(Rack::Utils.parse_query(URI(response.location).query)['error_message']).to eq(I18n.t('instagram.wrong_account'))
        expect(Rack::Utils.parse_query(URI(response.location).query)['error_type']).to eq('Instagram::ConnectionError')
      end

      it 'creates instagram channel and inbox' do
        expect do
          get :show, params: valid_params
        end.to change(Channel::Instagram, :count).by(1).and change(Inbox, :count).by(1)

        expect(Channel::Instagram.last.access_token).to eq('long_lived_test_token')
        expect(Channel::Instagram.last.instagram_id).to eq('12345')
        expect(Channel::Instagram.last.provider_name).to eq('test_user')
        expect(Inbox.last.name).to eq('test_user')

        expect(Inbox.last.channel.reauthorization_required?).to be false
        expect(response).to redirect_to(app_instagram_inbox_agents_url(account_id: account.id, inbox_id: Inbox.last.id))
      end

      it 'updates existing channel with new token' do
        existing_channel = create(:channel_instagram, account: account, instagram_id: '12345', access_token: 'old_token')
        existing_channel.inbox.update!(name: 'Custom Inbox Name')
        allow(controller).to receive(:instagram_token_inbox_id).and_return(existing_channel.inbox.id)

        expect do
          get :show, params: valid_params
        end.to not_change(Channel::Instagram, :count).and not_change(Inbox, :count)

        existing_channel.reload
        expect(existing_channel.access_token).to eq('long_lived_test_token')
        expect(existing_channel.instagram_id).to eq('12345')
        expect(existing_channel.provider_name).to eq('test_user')
        expect(existing_channel.inbox.reload.name).to eq('Custom Inbox Name')
        expect(existing_channel.reauthorization_required?).to be false
      end
    end

    context 'when user denies authorization' do
      it 'redirects to error page with authorization error details' do
        get :show, params: error_params

        expect(response).to redirect_to(
          app_new_instagram_inbox_url(
            account_id: account.id,
            error_type: 'access_denied',
            code: 400,
            error_message: 'User denied access'
          )
        )
      end
    end

    context 'when an OAuth error occurs' do
      before do
        oauth_error = OAuth2::Error.new(
          OpenStruct.new(
            body: { error_type: 'OAuthException', code: 400, error_message: 'Invalid OAuth code' }.to_json,
            status: 400
          )
        )
        allow(auth_code_object).to receive(:get_token).and_raise(oauth_error)
      end

      it 'handles OAuth errors and redirects to error page' do
        get :show, params: valid_params

        expected_url = app_new_instagram_inbox_url(
          account_id: account.id,
          error_type: 'OAuthException',
          code: 400,
          error_message: 'Invalid OAuth code'
        )
        expect(response).to redirect_to(expected_url)
      end
    end

    context 'when a standard error occurs' do
      before do
        allow(auth_code_object).to receive(:get_token).and_raise(StandardError.new('Unknown error'))
      end

      it 'handles standard errors and redirects to error page' do
        get :show, params: valid_params

        expected_url = app_new_instagram_inbox_url(
          account_id: account.id,
          error_type: 'StandardError',
          code: 500,
          error_message: 'Unknown error'
        )
        expect(response).to redirect_to(expected_url)
      end
    end
  end
end
