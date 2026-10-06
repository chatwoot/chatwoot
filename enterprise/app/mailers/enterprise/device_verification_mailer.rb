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

    send_mail_with_liquid(to: user.email, subject: "Your #{brand_name} verification code")
  end

  def new_device(user, meta = {})
    return unless smtp_config_set_or_development?

    @user = user
    @meta = meta || {}

    send_mail_with_liquid(to: user.email, subject: "A new device signed in to your #{brand_name} account")
  end

  private

  def brand_name
    GlobalConfig.get_value('BRAND_NAME').presence || 'Chatwoot'
  end

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

  # Resolved here, in the delivery job, so the geo lookup stays off the sign-in
  # request. Blank when the IP cannot be resolved (e.g. loopback or no geo DB),
  # in which case the template simply omits the location row.
  def resolved_location
    return @meta[:location] if @meta[:location].present?
    return if @meta[:ip].blank?

    result = IpLookupService.new.perform(@meta[:ip])
    return if result.blank?

    [result.city, result.country].reject(&:blank?).join(', ').presence
  end

  def liquid_locals
    super.merge(
      brand_name: brand_name,
      recipient_name: @user.name.presence || @user.email,
      code: @code,
      ip: @meta[:ip],
      browser_name: @meta[:browser_name],
      platform_name: @meta[:platform_name],
      location: resolved_location,
      reset_password_url: reset_password_url
    )
  end
end
