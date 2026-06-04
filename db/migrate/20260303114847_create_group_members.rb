class CreateGroupMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :group_members do |t|
      t.bigint :group_contact_id, null: false
      t.bigint :contact_id, null: false
      t.integer :role, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end

    add_index :group_members, %i[group_contact_id contact_id], unique: true
    add_index :group_members, %i[group_contact_id is_active]
    add_index :group_members, :contact_id
    add_index :group_members, :group_contact_id
    add_foreign_key :group_members, :contacts, column: :group_contact_id
    add_foreign_key :group_members, :contacts, column: :contact_id
  end
end
