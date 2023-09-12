class AdministratorNotifications::AccountMailer < ApplicationMailer
  def initial_warning(account)
    return unless smtp_config_set_or_development?

    @account = account
    @initial_warning_days = initial_warning_days
    @number_of_days = intermediary_days
    @admin_name = admin.name
    @deletion_date = deletion_for_intital_warning_date.strftime('%d %b %Y')
    account.update!(deletion_email_reminder: :initial_reminder, email_sent_at: Time.current)
    subject = 'OneHash Chat Account Deletion Warning'
    send_mail_with_liquid(to: admin_email, subject: subject) and return
  end

  def second_warning(account)
    return unless smtp_config_set_or_development?

    @account = account
    @initial_warning_days = initial_warning_days + intermediary_days
    @number_of_days = deletion_days
    @admin_name = admin.name
    @deletion_date = deletion_for_second_warning_date.strftime('%d %b %Y')
    account.update(deletion_email_reminder:  :second_reminder, email_sent_at: Time.current)

    subject = 'OneHash Chat Account Deletion Warning'
    send_mail_with_liquid(to: admin_email, subject: subject) and return
  end

  def account_deletion(account)
    return unless smtp_config_set_or_development?

    @account = account
    @warning_days = initial_warning_days + intermediary_days + deletion_days
    @admin_name = admin.name
    @deletion_date = Date.today.strftime('%d %b %Y')
    subject = 'OneHash Chat Account Deletion'
    account.update(deletion_email_reminder: :deletion_pending, email_sent_at: Time.current)
    @action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/"
    send_mail_with_liquid(to: admin_email, subject: subject) and return
  end

  private

  def admin
    @account.account_users.where(inviter_id: nil).last.user
  end

  def admin_email
    admin.email
  end

  def initial_warning_days
    config_name = 'INITIAL_WARNING_AFTER_DAYS'
    no_of_days = GlobalConfig.get(config_name)[config_name] || 28
    no_of_days.to_i
  end

  def intermediary_days
    config_name = 'INTEMEDIATRY_WARNING'
    no_of_days = GlobalConfig.get(config_name)[config_name] || 2
    no_of_days.to_i
  end

  def deletion_days
    config_name = 'ACCOUNT_DELETION_DAYS_AFTER_INTEMEDIATRY_WARNING'
    no_of_days = GlobalConfig.get(config_name)[config_name] || 2
    no_of_days.to_i
  end

  def deletion_for_intital_warning_date
    Date.current + intermediary_days.days + deletion_days.days
  end

  def deletion_for_second_warning_date
    Date.current + deletion_days.days
  end
end
