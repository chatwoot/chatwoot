class AddPublicNameToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :public_name, :string
  end
end
