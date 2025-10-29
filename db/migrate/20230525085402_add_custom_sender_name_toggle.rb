class AddCustomSenderNameToggle < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:inboxes, :sender_name_type)
      add_column :inboxes, :sender_name_type, :integer, default: 0, null: false
    end
  end
end
