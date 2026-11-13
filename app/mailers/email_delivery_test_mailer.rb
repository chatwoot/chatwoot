class EmailDeliveryTestMailer < ApplicationMailer
  def delivery_test(email, name)
    return unless smtp_config_set_or_development?

    @recipient_name = name.presence || email
    send_mail_with_liquid(to: email, subject: I18n.t('super_admin.users.email_suppression.test_email.subject', brand_name: brand_name))
  end

  private

  def brand_name
    GlobalConfig.get_value('BRAND_NAME').presence || 'Chatwoot'
  end

  def liquid_locals
    super.merge(brand_name: brand_name, recipient_name: @recipient_name)
  end
end
