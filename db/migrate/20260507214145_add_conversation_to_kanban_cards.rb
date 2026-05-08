class AddConversationToKanbanCards < ActiveRecord::Migration[7.1]
  def up
    add_reference :kanban_cards, :conversation, foreign_key: { on_delete: :nullify }, null: true

    remove_index :kanban_cards, :contact_id, name: 'index_kanban_cards_on_contact_id_unique'
    add_index :kanban_cards, :conversation_id,
              unique: true,
              where: 'conversation_id IS NOT NULL',
              name: 'index_kanban_cards_on_conversation_id_unique'
  end

  def down
    remove_index :kanban_cards, name: 'index_kanban_cards_on_conversation_id_unique'
    add_index :kanban_cards, :contact_id, unique: true, name: 'index_kanban_cards_on_contact_id_unique'
    remove_reference :kanban_cards, :conversation
  end
end
