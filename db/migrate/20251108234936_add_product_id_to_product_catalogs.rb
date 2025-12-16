class AddProductIdToProductCatalogs < ActiveRecord::Migration[7.1]
  def change
    add_column :product_catalogs, :product_id, :string
    add_index :product_catalogs, :product_id, unique: true
  end
end
