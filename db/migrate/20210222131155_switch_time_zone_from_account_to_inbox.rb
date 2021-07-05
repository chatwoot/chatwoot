class SwitchTimeZoneFromAccountToInbox < ActiveRecord::Migration[6.0]
  def change
    remove_column :accounts, :timezone, :string, default: 'UTC'
    add_column :inboxes, :timezone, :string, default: 'UTC'
  end
end
