require 'rails_helper'

RSpec.describe 'API bearer authentication', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:token) { user.access_token.token }

  it 'accepts an existing user token in the Authorization header' do
    get '/api/v1/profile', headers: { Authorization: "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['id']).to eq(user.id)
  end

  it 'uses the bearer token when the legacy header contains a different token' do
    other_user = create(:user)
    get '/api/v1/profile', headers: { Authorization: "bearer #{token}", api_access_token: other_user.access_token.token }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['id']).to eq(user.id)
  end

  it 'does not fall back to the legacy header for an empty bearer token' do
    get '/api/v1/profile', headers: { Authorization: 'Bearer', api_access_token: token }
    expect(response).to have_http_status(:unauthorized)
  end

  it 'does not fall back to dashboard headers for an invalid API bearer' do
    get '/api/v1/profile', headers: user.create_new_auth_token.merge(Authorization: 'Bearer invalid')
    expect(response).to have_http_status(:unauthorized)
  end

  it 'preserves encoded dashboard bearer authentication' do
    credentials = user.create_new_auth_token
    get '/api/v1/profile', headers: { Authorization: "Bearer #{Base64.strict_encode64(credentials.to_json)}" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['id']).to eq(user.id)
  end

  it 'preserves bot permissions for allowed and disallowed endpoints' do
    bot = create(:agent_bot, account: account)
    conversation = create(:conversation, account: account)
    headers = { Authorization: "Bearer #{bot.access_token.token}" }
    get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: headers
    expect(response).to have_http_status(:ok)
    get '/api/v1/profile', headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it 'accepts platform app tokens and preserves resource restrictions' do
    platform_app = create(:platform_app)
    headers = { Authorization: "Bearer #{platform_app.access_token.token}" }
    get "/platform/api/v1/accounts/#{account.id}", headers: headers
    expect(response).to have_http_status(:unauthorized)
    platform_app.platform_app_permissibles.create!(permissible: account)
    get "/platform/api/v1/accounts/#{account.id}", headers: headers
    expect(response).to have_http_status(:ok)
  end

  it 'rejects a user token on the Platform API' do
    get "/platform/api/v1/accounts/#{account.id}", headers: { Authorization: "Bearer #{token}" }
    expect(response).to have_http_status(:unauthorized)
  end
end
