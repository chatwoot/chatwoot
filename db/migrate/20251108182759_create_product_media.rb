class CreateProductMedia < ActiveRecord::Migration[7.1]
  def change
    create_table :product_media do |t|
      t.references :product_catalog, null: false, foreign_key: true
      t.string :file_type, null: false
      t.string :file_name, null: false
      t.string :file_url, null: false
      t.string :thumbnail_url
      t.integer :file_size
      t.string :mime_type
      t.integer :display_order, default: 0
      t.boolean :is_primary, default: false

      t.timestamps
    end

    add_index :product_media, :file_type
    add_index :product_media, :is_primary
    add_index :product_media, [:product_catalog_id, :display_order]
  end
end
