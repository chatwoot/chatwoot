class SecurityMailer < ApplicationMailer
  def account_locked(user)
    return unless smtp_config_set_or_development?

    @agent = user
    @unlock_minutes = Devise.unlock_in.in_minutes.to_i
    send_mail_with_liquid(to: user.email, subject: 'Sign-in to your account is temporarily locked') and return
  end

  private

  def liquid_locals
    super.merge(unlock_minutes: @unlock_minutes)
  end
end
