class AddMetadataToProductCatalogs < ActiveRecord::Migration[7.0]
  def change
    add_column :product_catalogs, :metadata, :jsonb, default: {}, null: false
    add_index :product_catalogs, :metadata, using: :gin
  end
end
