class AddBlockedUntilToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :blocked_until, :datetime, null: true, default: nil
    add_index  :contacts, :blocked_until
  end
end
