class CreateDataImportErrors < ActiveRecord::Migration[7.1]
  def change
    create_table :data_import_errors do |t|
      t.references :data_import, null: false, index: true
      t.references :data_import_item, null: true, index: true
      t.string :source_object_type
      t.string :source_object_id
      t.string :error_code, null: false
      t.text :message
      t.jsonb :details, default: {}, null: false

      t.timestamps
    end

    add_index :data_import_errors, [:source_object_type, :source_object_id], name: 'idx_data_import_errors_on_source'
  end
end
