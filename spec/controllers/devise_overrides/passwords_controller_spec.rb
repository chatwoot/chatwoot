require 'rails_helper'

RSpec.describe DeviseOverrides::PasswordsController, type: :controller do
  include Devise::Test::ControllerHelpers

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'PUT #update' do
    let(:user) { create(:user, password: 'Test@123456') }

    it 'unlocks a locked account on successful password reset' do
      user.update!(failed_attempts: Devise.maximum_attempts)
      user.lock_access!
      raw_token = user.send_reset_password_instructions

      put :update, params: {
        reset_password_token: raw_token,
        password: 'NewPassword@123',
        password_confirmation: 'NewPassword@123'
      }

      expect(response).to have_http_status(:success)
      expect(user.reload.access_locked?).to be false
      expect(user.failed_attempts).to eq(0)
    end

    it 'does not unlock with an invalid reset token' do
      user.lock_access!

      put :update, params: {
        reset_password_token: 'garbage',
        password: 'NewPassword@123',
        password_confirmation: 'NewPassword@123'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.access_locked?).to be true
    end
  end
end
