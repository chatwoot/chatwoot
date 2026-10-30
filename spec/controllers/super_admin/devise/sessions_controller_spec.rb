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

  describe 'POST /super_admin/sign_in with two-factor authentication enabled' do
    let(:super_admin) { create(:super_admin, password: 'Password1!') }

    before do
      skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
      super_admin.enable_two_factor!
      super_admin.update!(otp_required_for_login: true)
    end

    def submit_password
      post '/super_admin/sign_in', params: { super_admin: { email: super_admin.email, password: 'Password1!' } }
    end

    def submit_code(code)
      post '/super_admin/sign_in', params: { super_admin: { otp_code: code } }
    end

    def signed_in?
      get '/super_admin/accounts'
      response.successful?
    end

    it 'asks for the code instead of signing in' do
      submit_password
      expect(response).to redirect_to(super_admin_session_path)

      get '/super_admin/sign_in'
      expect(response.body).to include('super_admin[otp_code]')
      expect(signed_in?).to be(false)
    end

    it 'signs in with a valid authenticator code' do
      submit_password
      submit_code(super_admin.reload.current_otp)

      expect(response).to redirect_to(super_admin_root_path)
      expect(signed_in?).to be(true)
    end

    it 'signs in with a backup code only once' do
      backup_code = super_admin.generate_backup_codes!.first

      submit_password
      submit_code(backup_code)
      expect(signed_in?).to be(true)

      delete '/super_admin/sign_out'
      submit_password
      submit_code(backup_code)
      expect(signed_in?).to be(false)
    end

    it 'does not sign in with an invalid code' do
      submit_password
      submit_code('000000')

      expect(response).to redirect_to(super_admin_session_path)
      expect(signed_in?).to be(false)
    end

    it 'treats a blank code as an invalid code' do
      submit_password
      submit_code('')

      expect(flash[:error]).to eq(I18n.t('super_admin.login.mfa_invalid'))
    end

    it 'stops accepting codes for the admin after five wrong attempts' do
      submit_password
      5.times { submit_code('000000') }

      submit_password
      submit_code(super_admin.reload.current_otp)
      expect(signed_in?).to be(false)
    end

    it 'does not sign in when the code arrives after the challenge expires' do
      submit_password

      travel 6.minutes do
        submit_code(super_admin.reload.current_otp)
        expect(signed_in?).to be(false)
      end
    end

    it 'does not sign in with a code alone' do
      submit_code(super_admin.current_otp)

      expect(response).to redirect_to(super_admin_session_path)
      expect(signed_in?).to be(false)
    end
  end

  describe 'Devise routes other than sign in' do
    it 'does not expose password reset, sign up or confirmation under /super_admin' do
      expect(Rails.application.routes.url_helpers).not_to respond_to(:super_admin_password_path)
      expect(Rails.application.routes.url_helpers).not_to respond_to(:super_admin_registration_path)
      expect(Rails.application.routes.url_helpers).not_to respond_to(:super_admin_confirmation_path)
    end
  end
end
