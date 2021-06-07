require 'rails_helper'

RSpec.describe 'Profile API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/profile' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns current user information' do
        get '/api/v1/profile',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(agent.id)
        expect(json_response['email']).to eq(agent.email)
        expect(json_response['access_token']).to eq(agent.access_token.token)
      end
    end
  end

  describe 'PUT /api/v1/profile' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put '/api/v1/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, password: 'Test123!', account: account, role: :agent) }

      it 'updates the name & email' do
        new_email = Faker::Internet.email
        put '/api/v1/profile',
            params: { profile: { name: 'test', email: new_email } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        agent.reload
        expect(json_response['id']).to eq(agent.id)
        expect(json_response['email']).to eq(agent.email)
        expect(agent.email).to eq(new_email)
      end

      it 'updates the password when current password is provided' do
        put '/api/v1/profile',
            params: { profile: { current_password: 'Test123!', password: 'Test1234!', password_confirmation: 'Test1234!' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(agent.reload.valid_password?('Test1234!')).to eq true
      end

      it 'throws error when current password provided is invalid' do
        put '/api/v1/profile',
            params: { profile: { current_password: 'Test', password: 'test123', password_confirmation: 'test123' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'updates avatar' do
        # no avatar before upload
        expect(agent.avatar.attached?).to eq(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        put '/api/v1/profile',
            params: { profile: { avatar: file } },
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        agent.reload
        expect(agent.avatar.attached?).to eq(true)
      end

      it 'updates the availability status' do
        put '/api/v1/profile',
            params: { profile: { availability: 'offline' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(::OnlineStatusTracker.get_status(account.id, agent.id)).to eq('offline')
      end

      it 'updates the ui settings' do
        put '/api/v1/profile',
            params: { profile: { ui_settings: { is_contact_sidebar_open: false } } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['ui_settings']['is_contact_sidebar_open']).to eq(false)
      end
    end
  end
end
