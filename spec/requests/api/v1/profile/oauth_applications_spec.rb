require 'rails_helper'

RSpec.describe 'Profile OAuth Applications API', type: :request do
  let(:account) { create(:account, name: 'Acme Support') }
  let(:user) { create(:user, account: account) }
  let(:auth_headers) { user.create_new_auth_token }
  let(:application) { Doorkeeper::Application.create!(name: 'ChatGPT', redirect_uri: 'https://chatgpt.com/callback', confidential: false) }
  let(:token_attributes) do
    { application: application, resource_owner_id: user.id, account_id: account.id, scopes: 'conversations:read messages:write',
      use_refresh_token: true, expires_in: 2.hours }
  end
  let(:grant_attributes) do
    { application: application, resource_owner_id: user.id, account_id: account.id, redirect_uri: application.redirect_uri, expires_in: 600 }
  end

  before do
    InstallationConfig.where(name: 'OAUTH_PROVIDER_ENABLED').delete_all
    InstallationConfig.create!(name: 'OAUTH_PROVIDER_ENABLED', value: true)
  end

  after { GlobalConfig.clear_cache }

  describe 'GET /api/v1/profile/oauth_applications' do
    it 'returns 404 when the provider is disabled' do
      InstallationConfig.find_by(name: 'OAUTH_PROVIDER_ENABLED').update!(value: false)

      get '/api/v1/profile/oauth_applications', headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without auth' do
      get '/api/v1/profile/oauth_applications', as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the apps the user has connected with their scopes and account' do
      grant = Doorkeeper::AccessGrant.create!(grant_attributes)
      Doorkeeper::AccessToken.create!(token_attributes)

      get '/api/v1/profile/oauth_applications', headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to contain_exactly(
        include('id' => application.id, 'name' => 'ChatGPT', 'scopes' => %w[conversations:read messages:write],
                'accounts' => ['Acme Support'], 'authorized_at' => grant.created_at.as_json)
      )
    end

    it 'lists an app once when the user connected it to several accounts' do
      other_account = create(:account, name: 'Beta Support')
      create(:account_user, account: other_account, user: user)
      Doorkeeper::AccessToken.create!(token_attributes)
      Doorkeeper::AccessToken.create!(token_attributes.merge(account_id: other_account.id, scopes: 'contacts:read'))

      get '/api/v1/profile/oauth_applications', headers: auth_headers, as: :json

      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first['accounts']).to contain_exactly('Acme Support', 'Beta Support')
      expect(response.parsed_body.first['scopes']).to contain_exactly('conversations:read', 'messages:write', 'contacts:read')
    end

    it 'excludes apps whose tokens are all revoked' do
      Doorkeeper::AccessToken.create!(token_attributes).revoke

      get '/api/v1/profile/oauth_applications', headers: auth_headers, as: :json

      expect(response.parsed_body).to be_empty
    end

    it 'excludes apps connected by other users' do
      Doorkeeper::AccessToken.create!(token_attributes.merge(resource_owner_id: create(:user, account: account).id))

      get '/api/v1/profile/oauth_applications', headers: auth_headers, as: :json

      expect(response.parsed_body).to be_empty
    end
  end

  describe 'DELETE /api/v1/profile/oauth_applications/:id' do
    it 'returns 401 without auth' do
      delete "/api/v1/profile/oauth_applications/#{application.id}", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'revokes the tokens and the pending grants of the user for that app' do
      token = Doorkeeper::AccessToken.create!(token_attributes)
      grant = Doorkeeper::AccessGrant.create!(grant_attributes)

      delete "/api/v1/profile/oauth_applications/#{application.id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      expect(token.reload).to be_revoked
      expect(grant.reload).to be_revoked
    end

    it 'leaves the tokens of other users for the same app' do
      Doorkeeper::AccessToken.create!(token_attributes)
      other_token = Doorkeeper::AccessToken.create!(token_attributes.merge(resource_owner_id: create(:user, account: account).id))

      delete "/api/v1/profile/oauth_applications/#{application.id}", headers: auth_headers, as: :json

      expect(other_token.reload).not_to be_revoked
    end

    it 'returns 404 for an app the user has not connected' do
      delete "/api/v1/profile/oauth_applications/#{application.id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
