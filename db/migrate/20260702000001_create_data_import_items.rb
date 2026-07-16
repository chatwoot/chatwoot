class CreateDataImportItems < ActiveRecord::Migration[7.1]
  def change
    create_data_import_items
    add_data_import_item_indexes
  end

  private

  def create_data_import_items
    create_table :data_import_items do |t|
      t.references :data_import, null: false, index: true
      t.string :source_provider, null: false
      t.string :source_object_type, null: false
      t.string :source_object_id, null: false
      t.integer :status, default: 0, null: false
      t.string :chatwoot_record_type
      t.bigint :chatwoot_record_id
      t.integer :attempt_count, default: 0, null: false
      t.string :last_error_code
      t.text :last_error_message
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end
  end

  def add_data_import_item_indexes
    add_index :data_import_items,
              [:data_import_id, :source_object_type, :source_object_id],
              unique: true,
              name: 'idx_data_import_items_on_import_and_source'
    add_index :data_import_items, [:chatwoot_record_type, :chatwoot_record_id], name: 'idx_data_import_items_on_record'
    add_index :data_import_items, [:source_provider, :source_object_type, :source_object_id], name: 'idx_data_import_items_on_source'
  end
end
