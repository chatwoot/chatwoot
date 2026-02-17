class AddCachedSummaryToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :cached_summary, :text
    add_column :conversations, :cached_summary_at, :datetime
  end
end
