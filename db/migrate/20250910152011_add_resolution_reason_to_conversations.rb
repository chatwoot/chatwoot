class AddResolutionReasonToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :resolution_reason, :integer, default: nil
    add_index :conversations, :resolution_reason
  end
end