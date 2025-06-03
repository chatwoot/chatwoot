class RenameIsHandoverReminderToIsHandoverRemindedInConversations < ActiveRecord::Migration[7.0]
  def change
    rename_column :conversations, :is_handover_reminder, :is_handover_reminded
  end
end
