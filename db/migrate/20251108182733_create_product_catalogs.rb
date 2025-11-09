class CreateProductCatalogs < ActiveRecord::Migration[7.1]
  def change
    create_table :product_catalogs do |t|
      t.references :account, null: false, foreign_key: true
      t.string :industry, null: false
      t.string :product_service, null: false
      t.string :type, null: false
      t.string :subcategory
      t.decimal :list_price, precision: 10, scale: 2
      t.string :currency, default: 'MXN'
      t.text :description
      t.string :payment_options
      t.string :financing_term
      t.decimal :interest_rate, precision: 5, scale: 2
      t.string :attributes
      t.string :brand
      t.string :model
      t.string :year
      t.boolean :is_visible, default: true
      t.json :metadata
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.references :bulk_processing_request, foreign_key: true

      t.timestamps
    end

    add_index :product_catalogs, :is_visible
    add_index :product_catalogs, :created_at
    add_index :product_catalogs, [:industry, :product_service]
  end
end
