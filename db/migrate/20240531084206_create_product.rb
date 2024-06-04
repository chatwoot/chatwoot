class CreateProduct < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.references :account, null: false
      t.string :name, null: false
      t.string :short_name, null: false
      t.float :price, null: true
      t.boolean :disabled, null: false, default: false
      t.jsonb :custom_attributes, default: {}
      t.index [:account_id, :short_name], name: 'index_product_on_account_id_and_short_name', unique: true
      t.timestamps
    end
  end
end
