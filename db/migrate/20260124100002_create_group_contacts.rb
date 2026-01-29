class CreateGroupContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :group_contacts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.timestamps
    end

    add_index :group_contacts, %i[conversation_id contact_id], unique: true
  end
end
