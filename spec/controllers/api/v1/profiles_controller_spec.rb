require 'rails_helper'

RSpec.describe 'Profile API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/profile' do
    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns current user information' do
        get '/api/v1/profile',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(agent.id)
        expect(json_response['email']).to eq(agent.email)
      end
    end
  end

  describe 'PUT /api/v1/profile' do
    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        put '/api/v1/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates the name & email' do
        put '/api/v1/profile',
            params: { profile: { name: 'test', 'email': 'test@test.com' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        agent.reload
        expect(json_response['id']).to eq(agent.id)
        expect(json_response['email']).to eq(agent.email)
        expect(agent.email).to eq('test@test.com')
      end

      it 'updates the password' do
        put '/api/v1/profile',
            params: { profile: { password: 'test123', password_confirmation: 'test123' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end

      it 'updates avatar' do
        # no avatar before upload
        expect(agent.avatar.attached?).to eq(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        put '/api/v1/profile',
            params: { profile: { name: 'test', 'email': 'test@test.com', avatar: file } },
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        agent.reload
        expect(agent.avatar.attached?).to eq(true)
      end
    end
  end
end
