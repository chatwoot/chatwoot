class OtpMailer < ApplicationMailer
  def send_otp_email(user, otp)
    @user = user
    @otp = otp
    # Change URL to direct verification page without triggering new OTP generation
    @action_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/auth/verify-email?email=#{CGI.escape(user.email)}&otp_sent=true"

    mail(
      to: @user.email,
      subject: 'Verifikasi Email Anda - Jangkau.ai'
    )
  end

  def send_verification_success_email(user, account)
    @user = user
    @account = account
    @dashboard_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app"

    mail(
      to: @user.email,
      subject: 'Selamat! Email Anda Berhasil Diverifikasi - Jangkau.ai'
    )
  end

  private

  def ensure_current_account(account)
    @account = account
  end
end