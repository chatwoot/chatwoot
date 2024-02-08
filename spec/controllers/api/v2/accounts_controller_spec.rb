require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'POST /api/v2/accounts' do
    let(:email) { Faker::Internet.email }

    context 'when posting to accounts with correct parameters' do
      let(:account_builder) { double }
      let(:account) { create(:account) }
      let(:user) { create(:user, email: email, account: account) }

      before do
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
      end

      it 'calls account builder' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          allow(account_builder).to receive(:perform).and_return([user, account])

          params = { email: email, user: nil, locale: nil, password: 'Password1!' }

          post api_v2_accounts_url,
               params: params,
               as: :json

          expect(AccountBuilder).to have_received(:new).with(params.except(:password).merge(user_password: params[:password]))
          expect(account_builder).to have_received(:perform)
          expect(response.headers.keys).to include('access-token', 'token-type', 'client', 'expiry', 'uid')
          expect(response.body).to include('en')
        end
      end

      it 'calls ChatwootCaptcha' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          captcha = double
          allow(account_builder).to receive(:perform).and_return([user, account])
          allow(ChatwootCaptcha).to receive(:new).and_return(captcha)
          allow(captcha).to receive(:valid?).and_return(true)

          params = { email: email, user: nil, password: 'Password1!', locale: nil, h_captcha_client_response: '123' }

          post api_v2_accounts_url,
               params: params,
               as: :json

          expect(ChatwootCaptcha).to have_received(:new).with('123')
          expect(response.headers.keys).to include('access-token', 'token-type', 'client', 'expiry', 'uid')
          expect(response.body).to include('en')
        end
      end

      it 'renders error response on invalid params' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          allow(account_builder).to receive(:perform).and_return(nil)

          params = { email: nil, user: nil, locale: nil }

          post api_v2_accounts_url,
               params: params,
               as: :json

          expect(AccountBuilder).to have_received(:new).with(params.merge(user_password: params[:password]))
          expect(account_builder).to have_received(:perform)
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to eq({ message: I18n.t('errors.signup.failed') }.to_json)
        end
      end
    end

    context 'when ENABLE_ACCOUNT_SIGNUP env variable is set to false' do
      it 'responds 404 on requests' do
        params = { email: email }
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false' do
          post api_v2_accounts_url,
               params: params,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when ENABLE_ACCOUNT_SIGNUP env variable is set to api_only' do
      let(:account_builder) { double }
      let(:account) { create(:account) }
      let(:user) { create(:user, email: email, account: account) }

      it 'does not respond 404 on requests' do
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
        allow(account_builder).to receive(:perform).and_return([user, account])

        params = { email: email, user: nil, password: 'Password1!', locale: nil }
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'api_only' do
          post api_v2_accounts_url,
               params: params,
               as: :json

          expect(AccountBuilder).to have_received(:new).with(params.except(:password).merge(user_password: params[:password]))
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe 'PUT /api/v2/accounts/{account.id}' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:admin) { create(:user, account: account, role: :administrator) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v2/accounts/#{account.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthorized user' do
      it 'returns unauthorized' do
        put "/api/v2/accounts/#{account.id}",
            headers: agent.create_new_auth_token

        File.write('response.html', response.body)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      params = {
        name: 'New Name',
        locale: 'en',
        domain: 'example.com',
        support_email: 'care@example.com',
        auto_resolve_duration: 40
      }

      it 'modifies an account' do
        put "/api/v2/accounts/#{account.id}",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.name).to eq(params[:name])
        expect(account.reload.locale).to eq(params[:locale])
        expect(account.reload.domain).to eq(params[:domain])
        expect(account.reload.support_email).to eq(params[:support_email])
        expect(account.reload.auto_resolve_duration).to eq(params[:auto_resolve_duration])
      end

      it 'Throws error 422' do
        params[:name] = 'test' * 999

        put "/api/v2/accounts/#{account.id}",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['message']).to eq('Name is too long (maximum is 255 characters)')
      end
    end
  end
end
