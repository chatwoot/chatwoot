class AddIsVisibleToProductCatalogs < ActiveRecord::Migration[7.1]
  def change
    add_column :product_catalogs, :is_visible, :boolean, default: true, null: false
  end
end
