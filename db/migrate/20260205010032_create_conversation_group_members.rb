class CreateConversationGroupMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_group_members do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.integer :role, default: 0, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :conversation_group_members, [:conversation_id, :contact_id], unique: true
  end
end
