# [whisker] Email OTP passwordless login / verification endpoints.
class Auth::OtpController < DeviseTokenAuth::ApplicationController
  # POST /auth/otp/send
  # Body: { email: "user@email.com" }
  # Sends a 6-digit OTP to the email if the user's account allows it.
  def send_code
    email = params[:email].to_s.strip.downcase
    user = User.from_email(email)
    account = user&.accounts&.first

    unless user && (account.nil? || account.otp_via_email_enabled?)
      # Always respond with success to avoid user enumeration
      head :ok
      return
    end

    Whisker::EmailOtpService.new(email: email, account: account).send
    head :ok
  end

  # POST /auth/otp/verify
  # Body: { email: "...", code: "123456" }
  # Verifies the OTP and issues a Devise Token Auth session on success.
  def verify
    email = params[:email].to_s.strip.downcase
    code = params[:code].to_s
    user = User.from_email(email)
    account = user&.accounts&.first

    service = Whisker::EmailOtpService.new(email: email, account: account)
    unless user && service.verify(code)
      render json: { error: I18n.t('whisker.otp.invalid', default: 'Invalid or expired code') }, status: :unauthorized
      return
    end

    sign_in(:user, user, store: false)
    token = user.create_new_auth_token
    response.headers.merge!(token)
    render partial: 'devise/auth', formats: [:json], locals: { resource: user }
  end
end
