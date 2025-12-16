class ModifyProductCatalogsStructure < ActiveRecord::Migration[7.1]
  def change
    # Remove columns that are no longer needed
    remove_column :product_catalogs, :product_service, :string
    remove_column :product_catalogs, :currency, :string
    remove_column :product_catalogs, :financing_term, :string
    remove_column :product_catalogs, :interest_rate, :decimal
    remove_column :product_catalogs, :attributes, :string
    remove_column :product_catalogs, :brand, :string
    remove_column :product_catalogs, :model, :string
    remove_column :product_catalogs, :year, :string
    remove_column :product_catalogs, :is_visible, :boolean
    remove_column :product_catalogs, :metadata, :json
    remove_column :product_catalogs, :created_by_id, :bigint
    remove_column :product_catalogs, :updated_by_id, :bigint

    # Rename list_price to listPrice (keep as decimal)
    rename_column :product_catalogs, :list_price, :list_price_temp
    add_column :product_catalogs, :listPrice, :decimal, precision: 10, scale: 2

    # Add new columns
    add_column :product_catalogs, :productName, :string, null: false
    add_column :product_catalogs, :link, :text
    add_column :product_catalogs, :pdfLinks, :text
    add_column :product_catalogs, :photoLinks, :text
    add_column :product_catalogs, :videoLinks, :text

    # Update existing data
    reversible do |dir|
      dir.up do
        execute "UPDATE product_catalogs SET \"listPrice\" = list_price_temp"
      end
    end

    # Remove temporary column
    remove_column :product_catalogs, :list_price_temp, :decimal

    # Update indexes - remove old ones
    remove_index :product_catalogs, name: 'index_product_catalogs_on_industry_and_product_service', if_exists: true
    remove_index :product_catalogs, name: 'index_product_catalogs_on_is_visible', if_exists: true
    remove_index :product_catalogs, name: 'index_product_catalogs_on_created_by_id', if_exists: true
    remove_index :product_catalogs, name: 'index_product_catalogs_on_updated_by_id', if_exists: true
  end
end
