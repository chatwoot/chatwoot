class AddSummaryToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :summary, :text
    add_column :conversations, :summary_updated_at, :datetime
  end
end
