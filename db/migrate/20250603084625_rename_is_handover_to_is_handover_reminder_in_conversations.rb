class RenameIsHandoverToIsHandoverReminderInConversations < ActiveRecord::Migration[7.0]
  def change
    rename_column :conversations, :is_handover, :is_handover_reminder
  end
end
