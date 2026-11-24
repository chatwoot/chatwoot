class AddIconToConversationMonitors < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_monitors, :icon, :string, default: 'chat-3-line', null: false
    add_column :conversation_monitors, :icon_color, :string, default: '#3B82F6', null: false
  end
end
