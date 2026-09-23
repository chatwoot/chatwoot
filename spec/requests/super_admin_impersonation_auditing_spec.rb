require 'rails_helper'

RSpec.describe 'Super admin impersonation auditing', type: :request do
  let(:account) { create(:account) }
  let!(:user) { create(:user, account: account, password: 'Password1!') }
  let(:super_admin) { create(:super_admin) }
  let(:request_headers) { { 'REMOTE_ADDR' => '203.0.113.10', 'User-Agent' => 'Impersonation audit test' } }

  describe 'POST /auth/sign_in' do
    it 'does not audit minting an unused impersonation token' do
      expect { user.generate_sso_auth_token(impersonated_by: super_admin) }.not_to change(SuperAdminAuditLog, :count)
    end

    it 'records the staff member, target, accounts and request on successful redemption' do
      sso_token = user.generate_sso_auth_token(impersonated_by: super_admin)

      expect do
        post '/auth/sign_in', params: { email: user.email, sso_auth_token: sso_token }, headers: request_headers, as: :json
      end.to change(SuperAdminAuditLog, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(SuperAdminAuditLog.last).to have_attributes(
        action: 'impersonation_started', super_admin_id: super_admin.id, target_user_id: user.id,
        ip_address: '203.0.113.10', user_agent: 'Impersonation audit test', metadata: { 'account_ids' => [account.id] }
      )
      expect(user.valid_sso_auth_token?(sso_token)).to be(false)
    end

    it 'does not audit a regular password login' do
      expect do
        post '/auth/sign_in', params: { email: user.email, password: 'Password1!' }, as: :json
      end.not_to change(SuperAdminAuditLog, :count)

      expect(response).to have_http_status(:success)
    end

    it 'does not trust impersonation parameters on a regular SSO login' do
      expect do
        post '/auth/sign_in', params: {
          email: user.email, sso_auth_token: user.generate_sso_auth_token,
          impersonation: true, impersonated_by: super_admin.id
        }, as: :json
      end.not_to change(SuperAdminAuditLog, :count)

      expect(response).to have_http_status(:success)
    end

    it 'does not audit a failed login with an invalid SSO token' do
      expect do
        post '/auth/sign_in', params: { email: user.email, sso_auth_token: 'invalid' }, as: :json
      end.not_to change(SuperAdminAuditLog, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not audit a second redemption of a used impersonation token' do
      sso_token = user.generate_sso_auth_token(impersonated_by: super_admin)
      post '/auth/sign_in', params: { email: user.email, sso_auth_token: sso_token }, as: :json
      expect(response).to have_http_status(:success)

      expect do
        post '/auth/sign_in', params: { email: user.email, sso_auth_token: sso_token }, as: :json
      end.not_to change(SuperAdminAuditLog, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /auth/sign_out' do
    it 'records the end only after an impersonation session is revoked' do
      post '/auth/sign_in', params: { email: user.email, sso_auth_token: user.generate_sso_auth_token(impersonated_by: super_admin) }, as: :json
      auth_headers = response.headers.slice('access-token', 'client', 'uid')

      expect do
        delete '/auth/sign_out', headers: request_headers.merge(auth_headers)
      end.to change(SuperAdminAuditLog, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(user.reload.tokens).not_to have_key(auth_headers.fetch('client'))
      expect(SuperAdminAuditLog.last).to have_attributes(
        action: 'impersonation_ended', super_admin_id: super_admin.id, target_user_id: user.id,
        ip_address: '203.0.113.10', user_agent: 'Impersonation audit test', metadata: { 'account_ids' => [account.id] }
      )

      expect { delete '/auth/sign_out', headers: auth_headers }.not_to change(SuperAdminAuditLog, :count)
      expect(response).to have_http_status(:not_found)
    end

    it 'does not audit signing out a normal session on a user with an impersonation session' do
      post '/auth/sign_in', params: { email: user.email, sso_auth_token: user.generate_sso_auth_token(impersonated_by: super_admin) }, as: :json
      impersonation_client = response.headers.fetch('client')
      auth_headers = user.reload.create_new_auth_token

      expect { delete '/auth/sign_out', headers: auth_headers }.not_to change(SuperAdminAuditLog, :count)

      expect(response).to have_http_status(:success)
      expect(user.reload.tokens).to have_key(impersonation_client)
    end

    it 'does not audit an unauthenticated sign-out' do
      expect { delete '/auth/sign_out' }.not_to change(SuperAdminAuditLog, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'does not record an end when the impersonation session token is invalid' do
      post '/auth/sign_in', params: { email: user.email, sso_auth_token: user.generate_sso_auth_token(impersonated_by: super_admin) }, as: :json
      auth_headers = response.headers.slice('access-token', 'client', 'uid').merge('access-token' => 'invalid')

      expect { delete '/auth/sign_out', headers: auth_headers }.not_to change(SuperAdminAuditLog, :count)

      expect(response).to have_http_status(:not_found)
      expect(user.reload.tokens).to have_key(auth_headers.fetch('client'))
    end

    it 'records the original staff ID when the staff member was deleted during the session' do
      post '/auth/sign_in', params: { email: user.email, sso_auth_token: user.generate_sso_auth_token(impersonated_by: super_admin) }, as: :json
      auth_headers = response.headers.slice('access-token', 'client', 'uid')
      staff_id = super_admin.id
      super_admin.destroy!

      expect { delete '/auth/sign_out', headers: auth_headers }.to change(SuperAdminAuditLog, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(SuperAdminAuditLog.last).to have_attributes(action: 'impersonation_ended', super_admin_id: staff_id, target_user_id: user.id)
    end
  end
end
