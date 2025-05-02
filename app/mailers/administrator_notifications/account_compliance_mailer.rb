class AdministratorNotifications::AccountComplianceMailer < AdministratorNotifications::BaseMailer
  def account_deleted(account)
    return unless instance_admin_email.present?

    subject = subject_for(account)
    meta = build_meta(account)

    send_notification(subject, to: instance_admin_email, meta: meta)
  end

  private

  def build_meta(account)
    {
      'instance_url' => instance_url,
      'account_id' => account.id,
      'account_name' => account.name,
      'deleted_at' => Time.current.iso8601,
      'deletion_reason' => account.custom_attributes['marked_for_deletion_reason'] || 'not specified',
      'marked_for_deletion_at' => account.custom_attributes['marked_for_deletion_at'],
      'soft_deleted_users' => params[:soft_deleted_users] || []
    }
  end

  def subject_for(account)
    "Account Deletion Notice for #{account.id} - #{account.name}"
  end

  def instance_admin_email
    GlobalConfig.get('CHATWOOT_INSTANCE_ADMIN_EMAIL')['CHATWOOT_INSTANCE_ADMIN_EMAIL']
  end

  def instance_url
    ENV.fetch('FRONTEND_URL', 'not available')
  end
end
