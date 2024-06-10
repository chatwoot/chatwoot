class CreateContactTransaction < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_transactions do |t|
      t.references :account, null: false
      t.references :contact, null: false
      t.references :product, null: false
      t.datetime :po_date, null: true
      t.float :po_value, null: true
      t.string :po_note, null: true
      t.jsonb :custom_attributes, default: {}, null: false
      t.timestamps
    end
  end
end
