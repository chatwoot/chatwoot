# frozen_string_literal: true

class CreateKbResources < ActiveRecord::Migration[7.0]
  def change
    create_table :kb_resources do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.string :folder_path, null: false, default: '/'
      t.string :file_name, null: false
      t.string :s3_key, null: false
      t.string :content_type
      t.bigint :file_size
      t.boolean :is_visible, default: true, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :updated_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :kb_resources, :is_visible
    add_index :kb_resources, :s3_key, unique: true
    add_index :kb_resources, [:account_id, :folder_path]

    create_table :kb_resource_product_catalogs do |t|
      t.references :kb_resource, null: false, foreign_key: true
      t.references :product_catalog, null: false, foreign_key: true

      t.timestamps
    end

    add_index :kb_resource_product_catalogs,
              [:kb_resource_id, :product_catalog_id],
              unique: true,
              name: 'idx_kb_res_prod_cat_unique'
  end
end
