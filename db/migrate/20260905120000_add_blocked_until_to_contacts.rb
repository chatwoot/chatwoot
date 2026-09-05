class AddBlockedUntilToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :blocked_until, :datetime
  end
end
