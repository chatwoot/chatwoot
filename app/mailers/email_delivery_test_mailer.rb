class EmailDeliveryTestMailer < ApplicationMailer
  def delivery_test(user)
    return unless smtp_config_set_or_development?

    mail(to: user.email, subject: I18n.t('super_admin.users.email_suppression.test_email.subject')) do |format|
      format.text { render plain: I18n.t('super_admin.users.email_suppression.test_email.body') }
    end
  end
end
