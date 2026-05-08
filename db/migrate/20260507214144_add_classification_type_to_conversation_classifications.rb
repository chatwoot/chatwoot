class AddClassificationTypeToConversationClassifications < ActiveRecord::Migration[7.1]
  def up
    add_column :conversation_classifications, :classification_type, :integer, default: 0, null: false
    execute "UPDATE conversation_classifications SET classification_type = 1 WHERE name ILIKE 'venda ganha'"
    execute "UPDATE conversation_classifications SET classification_type = 2 WHERE name ILIKE 'venda perdida'"
  end

  def down
    remove_column :conversation_classifications, :classification_type
  end
end
