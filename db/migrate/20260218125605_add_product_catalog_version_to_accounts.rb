class AddProductCatalogVersionToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :product_catalog_version, :bigint, default: 0, null: false
  end
end
