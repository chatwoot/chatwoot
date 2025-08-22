class AddCsatExpiryHoursToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :csat_expiry_hours, :integer, default: nil
    add_column :inboxes, :csat_allow_resend_after_expiry, :boolean, default: false, null: false

    add_index :inboxes, :csat_expiry_hours
  end
end
