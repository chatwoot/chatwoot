class Enterprise::LoginLocationMailer < ApplicationMailer
  def new_location(user, meta = {})
    return unless smtp_config_set_or_development?

    @user = user
    @meta = meta || {}

    send_mail_with_liquid(to: user.email, subject: 'New sign-in to your Chatwoot account')
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
