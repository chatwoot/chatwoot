class AddGroupFieldsToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :group, :boolean, default: false, null: false
    add_column :conversations, :group_source_id, :string
    add_column :conversations, :group_title, :string

    add_index :conversations, :group
    add_index :conversations, %i[inbox_id group_source_id], unique: true, where: 'group_source_id IS NOT NULL',
                                                            name: 'index_conversations_on_inbox_id_and_group_source_id'
  end
end
