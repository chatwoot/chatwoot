class CreateDataImportMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :data_import_mappings do |t|
      t.integer :account_id, null: false
      t.references :data_import, null: false, index: true
      t.string :source_provider, null: false
      t.string :source_object_type, null: false
      t.string :source_object_id, null: false
      t.string :chatwoot_record_type, null: false
      t.bigint :chatwoot_record_id, null: false
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :data_import_mappings,
              [:account_id, :source_provider, :source_object_type, :source_object_id],
              unique: true,
              name: 'idx_data_import_mappings_on_account_and_source'
    add_index :data_import_mappings, [:chatwoot_record_type, :chatwoot_record_id], name: 'idx_data_import_mappings_on_record'
  end
end
