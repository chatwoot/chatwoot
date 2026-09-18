require 'rails_helper'

RSpec.describe 'Login location notification on sign-in', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, password: 'Password1!', account: account) }

  context 'when the feature is enabled' do
    before do
      create(:installation_config, name: 'LOGIN_LOCATION_NOTIFICATION_ENABLED', value: true)
      GlobalConfig.clear_cache
    end

    it 'enqueues the location check for a password sign-in' do
      expect do
        post new_user_session_url, params: { email: user.email, password: 'Password1!' }, as: :json
      end.to have_enqueued_job(Enterprise::LoginLocationNotificationJob)
      expect(response).to have_http_status(:success)
    end

    it 'does not enqueue for an SSO sign-in' do
      token = user.generate_sso_auth_token
      expect do
        post new_user_session_url, params: { email: user.email, sso_auth_token: token }, as: :json
      end.not_to have_enqueued_job(Enterprise::LoginLocationNotificationJob)
    end

    it 'still enqueues for a password sign-in carrying a bogus sso_auth_token param' do
      expect do
        post new_user_session_url,
             params: { email: user.email, password: 'Password1!', sso_auth_token: 'not-a-real-token' }, as: :json
      end.to have_enqueued_job(Enterprise::LoginLocationNotificationJob)
      expect(response).to have_http_status(:success)
    end

    it 'does not enqueue for a failed sign-in' do
      expect do
        post new_user_session_url, params: { email: user.email, password: 'wrong' }, as: :json
      end.not_to have_enqueued_job(Enterprise::LoginLocationNotificationJob)
    end
  end

  context 'when the feature is disabled' do
    it 'does not enqueue the location check' do
      expect do
        post new_user_session_url, params: { email: user.email, password: 'Password1!' }, as: :json
      end.not_to have_enqueued_job(Enterprise::LoginLocationNotificationJob)
    end
  end
end
