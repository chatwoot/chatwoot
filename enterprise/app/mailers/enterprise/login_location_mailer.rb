class Enterprise::LoginLocationMailer < ApplicationMailer
  # meta carries the recipient email captured at sign-in time, so a later email
  # change cannot redirect this alert to an attacker-controlled address.
  def new_location(meta = {})
    return unless smtp_config_set_or_development?

    @meta = meta || {}
    return if @meta[:email].blank?

    send_mail_with_liquid(to: @meta[:email], subject: 'New sign-in to your Chatwoot account')
  end

  private

  def reset_password_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/auth/reset/password"
  end

  def liquid_locals
    super.merge(
      city: @meta[:city],
      country: @meta[:country],
      ip: @meta[:ip],
      browser_name: @meta[:browser_name],
      platform_name: @meta[:platform_name],
      reset_password_url: reset_password_url
    )
  end
end
