class EmailDeliveryTestMailer < ApplicationMailer
  def delivery_test(user)
    return unless smtp_config_set_or_development?

    @user = user
    send_mail_with_liquid(to: user.email, subject: I18n.t('super_admin.users.email_suppression.test_email.subject', brand_name: brand_name))
  end

  private

  def brand_name
    GlobalConfig.get_value('BRAND_NAME').presence || 'Chatwoot'
  end

  def liquid_locals
    super.merge(brand_name: brand_name, recipient_name: @user.name.presence || @user.email)
  end
end
