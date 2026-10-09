class Captain::CustomerVerificationMailer < ApplicationMailer
  def verification_code(email, encrypted_code)
    code = Captain::CustomerEmailVerification.encryptor.decrypt_and_verify(encrypted_code)
    mail(to: email, subject: I18n.t('captain.customer_verification.subject')) do |format|
      format.text { render plain: I18n.t('captain.customer_verification.body', code: code) }
    end
  end

  private

  def handle_smtp_exceptions(exception)
    raise exception
  end
end
