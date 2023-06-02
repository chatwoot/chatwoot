class CreateConversationWithLabels < ActiveRecord::Migration[7.0]
  def change
    create_view :conversation_with_labels, materialized: true

    add_index :conversation_with_labels, :id, unique: true
    add_index :conversation_with_labels, :account_id
    add_index :conversation_with_labels, :status
    add_index :conversation_with_labels, :custom_attributes, using: :gin
    add_index :conversation_with_labels, :labels_array, using: :gin
    add_index :conversation_with_labels, :last_activity_at, order: { last_activity_at: :desc }
  end
end
