require 'rails_helper'

RSpec.describe 'Profile Sessions API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:auth_headers) { user.create_new_auth_token }
  let(:current_client_id) { auth_headers['client'] }

  describe 'GET /api/v1/profile/sessions' do
    it 'returns 401 without auth' do
      get '/api/v1/profile/sessions', as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the current user sessions ordered by last_activity_at desc' do
      older = user.user_sessions.create!(client_id: current_client_id, browser_name: 'Chrome', last_activity_at: 2.days.ago)
      newer = user.user_sessions.create!(client_id: 'other-client', browser_name: 'Firefox', last_activity_at: 1.hour.ago)
      user.update!(tokens: user.tokens.merge('other-client' => { 'token' => 'x', 'expiry' => 1.month.from_now.to_i }))

      get '/api/v1/profile/sessions', headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      sessions = response.parsed_body
      expect(sessions.map { |s| s['id'] }).to eq([newer.id, older.id])
      expect(sessions.find { |s| s['id'] == older.id }['current']).to be true
      expect(sessions.find { |s| s['id'] == newer.id }['current']).to be false
    end

    it 'excludes sessions whose token has expired' do
      live = user.user_sessions.create!(client_id: current_client_id, last_activity_at: 1.hour.ago)
      expired = user.user_sessions.create!(client_id: 'expired-client', last_activity_at: 1.day.ago)
      user.update!(tokens: user.tokens.merge('expired-client' => { 'token' => 'x', 'expiry' => 1.day.ago.to_i }))

      get '/api/v1/profile/sessions', headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      ids = response.parsed_body.map { |s| s['id'] }
      expect(ids).to include(live.id)
      expect(ids).not_to include(expired.id)
    end

    it 'returns an empty array when no sessions exist' do
      get '/api/v1/profile/sessions', headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq([])
    end
  end

  describe 'DELETE /api/v1/profile/sessions/:id' do
    let!(:other_session) { user.user_sessions.create!(client_id: 'other-client', last_activity_at: 1.hour.ago) }

    before do
      # Seed tokens hash so revoke can clean it up
      user.tokens = user.tokens.merge('other-client' => { 'token' => 'x', 'expiry' => 1.month.from_now.to_i })
      user.save!
    end

    it 'destroys the session and removes its token entry' do
      expect do
        delete "/api/v1/profile/sessions/#{other_session.id}", headers: auth_headers, as: :json
      end.to change(user.user_sessions, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(user.reload.tokens.keys).not_to include('other-client')
    end

    it 'returns 422 when trying to revoke the current session' do
      current = user.user_sessions.create!(client_id: current_client_id, last_activity_at: Time.current)

      delete "/api/v1/profile/sessions/#{current.id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to be_present
      expect(user.user_sessions.exists?(id: current.id)).to be true
    end

    it 'returns 404 for a nonexistent session id' do
      delete '/api/v1/profile/sessions/9999999', headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'does not allow revoking another user' do
      other_user = create(:user, account: account)
      foreign = other_user.user_sessions.create!(client_id: 'foreign', last_activity_at: 1.hour.ago)

      delete "/api/v1/profile/sessions/#{foreign.id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(other_user.user_sessions.exists?(id: foreign.id)).to be true
    end

    it 'returns 401 without auth' do
      delete "/api/v1/profile/sessions/#{other_session.id}", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
