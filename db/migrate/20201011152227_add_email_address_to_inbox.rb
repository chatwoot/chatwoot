class AddEmailAddressToInbox < ActiveRecord::Migration[6.0]
  def up
    add_column :inboxes, :email_address, :string
  end

  def down
    remove_column(:inboxes, :email_address)
  end
end
