class AddResolvedByContactToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :resolved_by_contact, :boolean, default: false, null: false
  end
end
