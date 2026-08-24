# [whisker] Mailer that delivers email OTP / verification codes.
class OtpMailer < ApplicationMailer
  def send_code(email, code)
    @code = code
    @account = params[:account]
    mail(to: email, subject: I18n.t('whisker.otp.subject', default: 'Your Whisker verification code'))
  end
end
