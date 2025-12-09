class CreateFunnelContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :funnel_contacts do |t|
      t.bigint :funnel_id, null: false
      t.bigint :contact_id, null: false
      t.string :column_id, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :funnel_contacts, :funnel_id
    add_index :funnel_contacts, :contact_id
    add_index :funnel_contacts, [:funnel_id, :contact_id], unique: true
    add_index :funnel_contacts, [:funnel_id, :column_id]
    add_foreign_key :funnel_contacts, :funnels, on_delete: :cascade
    add_foreign_key :funnel_contacts, :contacts, on_delete: :cascade
  end
end
