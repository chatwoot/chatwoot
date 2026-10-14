class Captain::EmailVerificationMailer < ApplicationMailer
  include EmailAddressParseable

  CODE_ENCRYPTOR = ActiveSupport::MessageEncryptor.new(
    ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key('captain_email_verification_code', 32)
  )
  private_constant :CODE_ENCRYPTOR

  # Checked before a code is issued, so the customer is never told an email was sent when none can be
  def self.deliverable?
    new.smtp_config_set_or_development?
  end

  # The code must never appear in serialized job arguments, since Sidekiq logs the payload when a job fails
  def self.deliver_code_later(inbox, email, code)
    with(account: inbox.account).verification_code(inbox, email, CODE_ENCRYPTOR.encrypt_and_sign(code)).deliver_later
  end

  def verification_code(inbox, email, encrypted_code)
    @inbox_name = inbox.sanitized_business_name
    @code = CODE_ENCRYPTOR.decrypt_and_verify(encrypted_code)

    # The code stays out of the subject, which is written to the mail log
    send_mail_with_liquid(
      to: email,
      from: format_email_with_name(@inbox_name, default_sender_email_address),
      subject: I18n.t('captain.email_verification.subject', inbox_name: @inbox_name)
    )
  end

  private

  def liquid_locals
    minutes = Captain::EmailVerification::Code::TTL.in_minutes.to_i
    super.merge(
      code: @code,
      heading: I18n.t('captain.email_verification.heading'),
      instructions: I18n.t('captain.email_verification.instructions', inbox_name: @inbox_name, minutes: minutes),
      ignore: I18n.t('captain.email_verification.ignore')
    )
  end
end
