class CreateOrderItems < ActiveRecord::Migration[7.0]
  def change
    create_table :order_items do |t|
      t.string :name
      t.integer :order_id
      t.integer :product_id
      t.integer :variation_id
      t.integer :quantity
      t.string :tax_class
      t.string :subtotal
      t.string :subtotal_tax
      t.string :total
      t.string :total_tax
      t.string :sku
      t.string :price
      t.timestamps
    end
  end
end
