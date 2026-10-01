class DataExports::NotificationJob < ApplicationJob
  queue_as :low

  def perform(data_export)
    data_export.with_lock do
      next unless data_export.completed? && data_export.notification_sent_at.nil? && data_export.requester_authorized?

      url = "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{data_export.account_id}/settings/data/exports/#{data_export.id}"
      AdministratorNotifications::AccountNotificationMailer.with(account: data_export.account)
                                                           .contact_export_complete(url, data_export.initiated_by.email).deliver_now
      data_export.update!(notification_sent_at: Time.current)
    end
  end
end
