class AddCustomSenderNameToggle < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :sender_name_type, :integer, default: 0, null: false
  end
end
