class AdministratorNotifications::AccountComplianceMailer < AdministratorNotifications::BaseMailer
  def account_deleted(account)
    return if instance_admin_email.blank?

    subject = subject_for(account)
    meta = build_meta(account)

    send_notification(subject, to: instance_admin_email, meta: meta)
  end

  private

  def build_meta(account)
    deleted_users = params[:soft_deleted_users] || []

    user_info_list = deleted_users.map do |user|
      {
        'user_id' => user[:id].to_s,
        'user_email' => user[:original_email].to_s
      }
    end

    {
      'instance_url' => instance_url,
      'account_id' => account.id,
      'account_name' => account.name,
      'deleted_at' => format_time(Time.current.iso8601),
      'deletion_reason' => account.custom_attributes['marked_for_deletion_reason'] || 'not specified',
      'marked_for_deletion_at' => format_time(account.custom_attributes['marked_for_deletion_at']),
      'soft_deleted_users' => user_info_list,
      'deleted_user_count' => user_info_list.size
    }
  end

  def format_time(time_string)
    return 'not specified' if time_string.blank?

    Time.zone.parse(time_string).strftime('%B %d, %Y %H:%M:%S %Z')
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
