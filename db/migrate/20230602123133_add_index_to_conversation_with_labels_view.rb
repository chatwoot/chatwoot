class AddIndexToConversationWithLabelsView < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :conversation_with_labels, :id, unique: true, algorithm: :concurrently
    add_index :conversation_with_labels, :account_id, algorithm: :concurrently
    add_index :conversation_with_labels, :status, algorithm: :concurrently
    add_index :conversation_with_labels, :custom_attributes, using: :gin, algorithm: :concurrently
    add_index :conversation_with_labels, :labels_array, using: :gin, algorithm: :concurrently
    add_index :conversation_with_labels, :last_activity_at, order: { last_activity_at: :desc }, algorithm: :concurrently
  end
end
