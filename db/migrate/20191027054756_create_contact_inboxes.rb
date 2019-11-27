class CreateContactInboxes < ActiveRecord::Migration[6.0]
  def change
    create_table :contact_inboxes do |t|
      t.references :contact, foreign_key: true, index: true
      t.references :inbox, foreign_key: true, index: true
      t.string :source_id, null: false

      t.timestamps
    end
    add_index :contact_inboxes, [:inbox_id, :source_id], unique: true
    add_index :contact_inboxes, [:source_id]
    remove_column :contacts, :inbox_id, :integer
    remove_column :contacts, :source_id, :integer
  end
end
