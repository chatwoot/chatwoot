class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, null: false, precision: 10, scale: 2
      t.string :product_type, null: false
      t.text :description
      t.jsonb :details, default: {}
      t.timestamps
    end

    add_index :products, :product_type
  end
end
