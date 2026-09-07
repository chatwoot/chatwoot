require 'rails_helper'

RSpec.describe 'Super Admin', type: :request do
  describe '/super_admin' do
    it 'renders the login page' do
      with_modified_env LOGRAGE_ENABLED: 'true' do
        get '/super_admin/sign_in'
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /super_admin/sign_in' do
    let(:super_admin) { create(:super_admin, password: 'Password1!') }

    it 'redirects to the dashboard on successful login' do
      post '/super_admin/sign_in', params: { super_admin: { email: super_admin.email, password: 'Password1!' } }
      expect(response).to redirect_to(super_admin_root_path)
    end

    it 'redirects back to the login page on invalid credentials' do
      post '/super_admin/sign_in', params: { super_admin: { email: super_admin.email, password: 'wrong' } }
      expect(response).to redirect_to(super_admin_session_path)
    end
  end
end
