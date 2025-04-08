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
    context 'when authorization is successful' do
      before do
        allow(auth_code_object).to receive(:get_token).and_return(access_token)
      end

      it 'creates instagram channel and inbox' do
        expect do
          get :show, params: valid_params
        end.to change(Channel::Instagram, :count).by(1).and change(Inbox, :count).by(1)

        expect(Channel::Instagram.last.access_token).to eq('long_lived_test_token')
        expect(Channel::Instagram.last.instagram_id).to eq('12345')
        expect(Inbox.last.name).to eq('test_user')

        expect(Inbox.last.channel.reauthorization_required?).to be false
        expect(response).to redirect_to(app_instagram_inbox_agents_url(account_id: account.id, inbox_id: Inbox.last.id))
      end

      it 'updates existing channel with new token' do
        # Create an existing channel
        existing_channel = create(:channel_instagram, account: account, instagram_id: '12345', access_token: 'old_token')
        create(:inbox, channel: existing_channel, account: account, name: 'old_username')

        expect do
          get :show, params: valid_params
        end.to not_change(Channel::Instagram, :count).and not_change(Inbox, :count)

        existing_channel.reload
        expect(existing_channel.access_token).to eq('long_lived_test_token')
        expect(existing_channel.instagram_id).to eq('12345')
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
