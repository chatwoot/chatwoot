class AddSummaryFieldsToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :summary, :text
    add_column :conversations, :summary_generated_at, :datetime
  end
end
