class AddCustomSenderNameToggle < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :custom_sender_name_enabled, :boolean, default: true, null: false
  end
end
