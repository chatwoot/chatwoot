require 'rails_helper'

# A reset link is good for `Devise.reset_password_within` (6 hours) after it was sent. The
# override of Devise's PasswordsController looked the token up and reset the password without
# asking, so an old link from a mailbox kept changing the password, and the answer signs the
# caller in (#762).
RSpec.describe 'Password reset', type: :request do
  let(:user) { create(:user, password: 'Password1!', password_confirmation: 'Password1!') }
  let!(:token) { user.send(:set_reset_password_token) }
  let(:params) { { reset_password_token: token, password: 'Password2!', password_confirmation: 'Password2!' } }

  it 'resets the password with a link inside the reset period' do
    put '/auth/password', params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(user.reload.valid_password?('Password2!')).to be(true)
  end

  it 'refuses a link past the reset period, and neither changes the password nor signs anybody in' do
    user.update_column(:reset_password_sent_at, (Devise.reset_password_within + 1.hour).ago) # rubocop:disable Rails/SkipsModelValidations

    put '/auth/password', params: params, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['message']).to eq('Invalid token')
    expect(response.headers['access-token']).to be_nil
    expect(user.reload.valid_password?('Password1!')).to be(true)
  end

  it 'refuses a token nobody was given' do
    put '/auth/password', params: params.merge(reset_password_token: 'not-a-token'), as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['message']).to eq('Invalid token')
  end

  # An agent invitation links to this same flow with a token minted when the email goes out,
  # and the reset is what confirms the invitee: an unconfirmed account that someone invited holds an invitation.
  context 'when the account was invited and never confirmed' do
    let(:user) { create(:user, password: 'Password1!', password_confirmation: 'Password1!', skip_confirmation: false) }

    before { create(:account_user, user: user, inviter: create(:user)) }

    it 'accepts the invitation days after it was sent' do
      user.update_column(:reset_password_sent_at, 2.days.ago) # rubocop:disable Rails/SkipsModelValidations

      put '/auth/password', params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?('Password2!')).to be(true)
      expect(user).to be_confirmed
    end

    # The reset confirms the account before the new password is validated: a rejected password
    # must not leave it confirmed, or the retry falls into the 6-hour window.
    it 'still accepts the invitation after a password the server rejects' do
      user.update_column(:reset_password_sent_at, 2.days.ago) # rubocop:disable Rails/SkipsModelValidations

      put '/auth/password', params: params.merge(password: 'short', password_confirmation: 'short'), as: :json
      expect(response).not_to have_http_status(:ok)
      expect(user.reload).not_to be_confirmed

      put '/auth/password', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?('Password2!')).to be(true)
    end

    it 'refuses an invitation token that was never sent' do
      user.update_column(:reset_password_sent_at, nil) # rubocop:disable Rails/SkipsModelValidations

      put '/auth/password', params: params, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'refuses an invitation past its own window' do
      user.update_column(:reset_password_sent_at, 8.days.ago) # rubocop:disable Rails/SkipsModelValidations

      put '/auth/password', params: params, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.valid_password?('Password1!')).to be(true)
    end
  end

  it 'refuses a token that was never sent' do
    user.update_column(:reset_password_sent_at, nil) # rubocop:disable Rails/SkipsModelValidations

    put '/auth/password', params: params, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.valid_password?('Password1!')).to be(true)
  end
end
