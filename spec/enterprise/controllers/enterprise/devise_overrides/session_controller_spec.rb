require 'rails_helper'

RSpec.describe 'Enterprise Audit API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, password: 'Password1!', account: account) }

  describe 'POST /sign_in' do
    it 'creates a sign_in audit event wwith valid credentials' do
      params = { email: user.email, password: 'Password1!' }

      expect do
        post new_user_session_url,
             params: params,
             as: :json
      end.to change(Enterprise::AuditLog, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.email)

      # Check if the sign_in event is created
      user.reload
      expect(user.audits.last.action).to eq('sign_in')
      expect(user.audits.last.associated_id).to eq(account.id)
      expect(user.audits.last.associated_type).to eq('Account')
    end

    it 'will not create a sign_in audit event with invalid credentials' do
      params = { email: user.email, password: 'invalid' }
      expect do
        post new_user_session_url,
             params: params,
             as: :json
      end.not_to change(Enterprise::AuditLog, :count)
    end
  end

  describe 'DELETE /sign_out' do
    context 'when it is an authenticated user' do
      it 'signs out the user and creates an audit event' do
        expect do
          delete '/auth/sign_out', headers: user.create_new_auth_token
        end.to change(Enterprise::AuditLog, :count).by(1)
        expect(response).to have_http_status(:success)

        user.reload

        expect(user.audits.last.action).to eq('sign_out')
        expect(user.audits.last.associated_id).to eq(account.id)
        expect(user.audits.last.associated_type).to eq('Account')
      end
    end
  end
end
