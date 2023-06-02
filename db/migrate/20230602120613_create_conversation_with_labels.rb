class CreateConversationWithLabels < ActiveRecord::Migration[7.0]
  def change
    create_view :conversation_with_labels, materialized: true
  end
end
