class DataImports::Csv::NotificationJob < ApplicationJob
  queue_as :low

  def perform(data_import)
    data_import.with_lock do
      next unless data_import.failed? || data_import.completed? || data_import.completed_with_errors?

      notification_key = "#{data_import.active_import_run_id}:#{data_import.status}"
      next if data_import.source_metadata['notification_sent'] == notification_key

      mailer = AdministratorNotifications::AccountNotificationMailer.with(account: data_import.account)
      if data_import.failed?
        mailer.contact_import_failed.deliver_now
      else
        mailer.contact_import_complete(data_import).deliver_now
      end
      data_import.update!(source_metadata: data_import.source_metadata.merge('notification_sent' => notification_key))
    end
  end
end
