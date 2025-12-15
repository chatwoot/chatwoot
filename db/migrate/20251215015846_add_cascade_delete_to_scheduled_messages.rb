class AddCascadeDeleteToScheduledMessages < ActiveRecord::Migration[7.1]
  def change
    # Remove a foreign key antiga
    remove_foreign_key :scheduled_messages, :conversations

    # Adiciona a nova foreign key com cascade delete
    add_foreign_key :scheduled_messages, :conversations, on_delete: :cascade
  end
end
