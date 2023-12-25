class RemoveEmailSentAtAndDeletionEmailReminderFromAccounts < ActiveRecord::Migration[7.0]
  def change
    remove_column :accounts, :email_sent_at, :datetime
    remove_column :accounts, :deletion_email_reminder, :integer
  end
end
