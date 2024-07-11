class CreateCartItems < ActiveRecord::Migration[7.0]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.timestamps
    end

    return if index_exists?(:cart_items, :cart_id)

    add_index :cart_items, :cart_id
  end
end
