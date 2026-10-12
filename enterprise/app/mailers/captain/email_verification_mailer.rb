class Captain::EmailVerificationMailer < ApplicationMailer
  def verification_code(inbox, email, encrypted_code)
    return unless smtp_config_set_or_development?

    @inbox_name = inbox.sanitized_business_name
    @code = Captain::EmailVerification.decrypt_code(encrypted_code)

    # The code stays out of the subject, which is written to the mail log
    send_mail_with_liquid(to: email, from: "#{@inbox_name} <#{sender_address}>", subject: "Your #{@inbox_name} verification code")
  end

  private

  def sender_address
    Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')).address
  end

  def liquid_locals
    super.merge(
      inbox_name: @inbox_name,
      code: @code,
      expires_in_minutes: Captain::EmailVerification::CODE_TTL.in_minutes.to_i
    )
  end
end
