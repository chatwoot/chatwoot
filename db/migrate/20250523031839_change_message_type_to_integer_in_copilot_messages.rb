class ChangeMessageTypeToIntegerInCopilotMessages < ActiveRecord::Migration[7.1]
  def up
    remove_column :copilot_messages, :message_type
    add_column :copilot_messages, :message_type, :integer, default: 0
  end

  def down
    remove_column :copilot_messages, :message_type
    add_column :copilot_messages, :message_type, :string, default: 'user'
  end
end
