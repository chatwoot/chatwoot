class ExpandDataImportsForIntercomImports < ActiveRecord::Migration[7.1]
  def change
    add_data_import_columns
    add_data_import_indexes
  end

  private

  def add_data_import_columns
    change_table :data_imports, bulk: true do |t|
      t.string :name
      t.string :source_type
      t.string :source_provider
      t.jsonb :import_types, default: [], null: false
      t.integer :initiated_by_id
      t.text :access_token
      t.jsonb :source_metadata, default: {}, null: false
      t.jsonb :stats, default: {}, null: false
      t.jsonb :cursor, default: {}, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :abandoned_at
      t.datetime :last_error_at
    end
  end

  def add_data_import_indexes
    add_index :data_imports, :initiated_by_id
    add_index :data_imports, :source_provider
  end
end
