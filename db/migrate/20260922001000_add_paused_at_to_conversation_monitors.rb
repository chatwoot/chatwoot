class AddPausedAtToConversationMonitors < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_monitors, :paused_at, :datetime
  end
end
