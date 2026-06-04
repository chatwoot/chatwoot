class CreateGroupContacts < ActiveRecord::Migration[7.0]
  def change
    create_table :group_contacts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :group_contacts, [:conversation_id, :contact_id],
              unique: true,
              name: 'index_group_contacts_on_conversation_id_and_contact_id'
  end
end
