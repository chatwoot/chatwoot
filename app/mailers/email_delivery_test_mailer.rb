class EmailDeliveryTestMailer < ApplicationMailer
  def delivery_test(user)
    return unless smtp_config_set_or_development?

    brand_name = GlobalConfig.get_value('BRAND_NAME').presence || 'Chatwoot'
    mail(to: user.email, subject: I18n.t('super_admin.users.email_suppression.test_email.subject', brand_name: brand_name)) do |format|
      format.text { render plain: I18n.t('super_admin.users.email_suppression.test_email.body', brand_name: brand_name) }
    end
  end
end
