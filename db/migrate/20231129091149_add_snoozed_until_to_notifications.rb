class AddSnoozedUntilToNotifications < ActiveRecord::Migration[7.0]
  def change
    add_column :notifications, :snoozed_until, :datetime
  end
end
