class AddLogToConversationToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :log_to_conversation, :boolean, default: false, null: false
  end
end
