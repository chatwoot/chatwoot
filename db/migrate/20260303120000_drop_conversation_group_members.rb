class DropConversationGroupMembers < ActiveRecord::Migration[7.1]
  def up
    drop_table :conversation_group_members, if_exists: true
  end

  def down
    create_table :conversation_group_members do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.integer :role, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end
    add_index :conversation_group_members, %i[conversation_id contact_id], unique: true
    add_index :conversation_group_members, %i[conversation_id is_active],
              name: 'index_conv_group_members_on_conversation_id_and_is_active'
  end
end
