class Enterprise::DeviceVerificationMailer < ApplicationMailer
  self.delivery_job = Enterprise::DeviceVerificationDeliveryJob

  def verification_code(user, encrypted_code, meta = {})
    # Raise, do not silently no-op: this code blocks sign-in, so a deployment with
    # device verification enabled but no SMTP is a misconfiguration that must surface
    # (the job then fails and retries) rather than leaving users at a 206 with no code.
    raise 'SMTP is not configured; cannot deliver device verification codes' unless smtp_config_set_or_development?

    @user = user
    @code = DeviceVerification.decrypt_code(encrypted_code)
    @meta = meta || {}

    send_mail_with_liquid(to: user.email, subject: 'Your Chatwoot sign-in verification code')
  end

  def new_device(user, meta = {})
    return unless smtp_config_set_or_development?

    @user = user
    @meta = meta || {}

    send_mail_with_liquid(to: user.email, subject: 'A new device signed in to your Chatwoot account')
  end

  private

  # ApplicationMailer swallows SMTP failures with a log line, which records a
  # failed challenge delivery as a successful job. Auth mail must fail loudly
  # so the delivery job retries and failures are observable.
  def handle_smtp_exceptions(exception)
    Rails.logger.error "Device verification mail delivery failed: #{exception.message}"
    raise exception
  end

  def reset_password_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/auth/reset/password"
  end

  def liquid_locals
    super.merge(
      code: @code,
      ip: @meta[:ip],
      browser_name: @meta[:browser_name],
      platform_name: @meta[:platform_name],
      location: @meta[:location],
      reset_password_url: reset_password_url
    )
  end
end
