class AddIconToConversationMonitors < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_monitors, :icon, :string, default: '', null: false
    add_column :conversation_monitors, :icon_color, :string, default: '', null: false
  end
end
