class AddUserIdentifierEnabledToInboxes < ActiveRecord::Migration[7.2]
  def change
    add_column :inboxes, :user_identifier_enabled, :boolean, default: false, null: false
  end
end
