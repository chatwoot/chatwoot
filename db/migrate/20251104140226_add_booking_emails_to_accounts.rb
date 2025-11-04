class AddBookingEmailsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :booking_emails, :jsonb, default: []
  end
end
