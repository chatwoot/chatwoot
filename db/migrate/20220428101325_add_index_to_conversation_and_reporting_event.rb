class AddIndexToConversationAndReportingEvent < ActiveRecord::Migration[6.1]
  def change
    add_index :conversations, :last_activity_at
    add_index :reporting_events, :conversation_id
  end
end
