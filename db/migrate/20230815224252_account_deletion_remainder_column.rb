class AccountDeletionRemainderColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :email_sent_at, :datetime
    add_column :accounts, :deletion_email_reminder, :integer, default: nil
  end
end
