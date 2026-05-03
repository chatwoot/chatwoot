class AddUniqueContactIndexToKanbanCards < ActiveRecord::Migration[7.1]
  def up
    # Remove duplicates keeping the oldest card per contact
    execute <<~SQL
      DELETE FROM kanban_cards
      WHERE id NOT IN (
        SELECT MIN(id) FROM kanban_cards GROUP BY contact_id
      )
    SQL

    remove_index :kanban_cards, name: 'index_kanban_cards_on_kanban_board_id_and_contact_id'
    add_index :kanban_cards, :contact_id, unique: true,
                                          name: 'index_kanban_cards_on_contact_id_unique'
  end

  def down
    remove_index :kanban_cards, name: 'index_kanban_cards_on_contact_id_unique'
    add_index :kanban_cards, %i[kanban_board_id contact_id], unique: true,
                                                             name: 'index_kanban_cards_on_kanban_board_id_and_contact_id'
  end
end
