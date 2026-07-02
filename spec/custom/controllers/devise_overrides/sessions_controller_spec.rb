require 'rails_helper'

# Verifies the fork's SSO-only login lockdown
# (custom/app/controllers/custom/devise_overrides/sessions_controller.rb).
RSpec.describe 'SSO-only login enforcement', type: :request do
  let!(:user) { create(:user) } # factory: confirmed, password 'Password1!'

  def password_login
    post '/auth/sign_in', params: { email: user.email, password: 'Password1!' }, as: :json
  end

  context 'when ENABLE_SSO_ONLY_LOGIN is off (default)' do
    it 'leaves password login working (overlay is inert)' do
      password_login
      expect(response).to have_http_status(:success)
    end
  end

  context 'when ENABLE_SSO_ONLY_LOGIN is on' do
    before do
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('ENABLE_SSO_ONLY_LOGIN', 'false').and_return('true')
    end

    it 'rejects password login with 401 and the sso_only_login code' do
      password_login
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error_code']).to eq('sso_only_login')
    end

    it 'still allows the Platform SSO-token login handoff' do
      post '/auth/sign_in',
           params: { email: user.email, sso_auth_token: user.generate_sso_auth_token },
           as: :json
      expect(response).to have_http_status(:success)
    end
  end
end
