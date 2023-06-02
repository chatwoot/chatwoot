class CreateConversationWithLabels < ActiveRecord::Migration[7.0]
  def change
    create_view :conversation_with_labels

    add_index :conversation_with_labels, :id, unique: true
    add_index :conversation_with_labels, :account_id
  end
end
