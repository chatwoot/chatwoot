class AddSlackChannelIdToConversationMonitors < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_monitors, :slack_channel_id, :string
  end
end
