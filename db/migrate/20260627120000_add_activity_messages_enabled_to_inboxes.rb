class AddActivityMessagesEnabledToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :activity_messages_enabled, :boolean, default: true, null: false
  end
end
