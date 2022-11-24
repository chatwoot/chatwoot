class AddCsatMessageToInbox < ActiveRecord::Migration[6.0]
  def up
    add_column :inboxes, :csat_message, :string
  end

  def down
    remove_column(:inboxes, :csat_message)
  end
end
