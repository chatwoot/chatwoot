class AddNonIdentifiableRecordsToDataImports < ActiveRecord::Migration[7.0]
  def change
    add_column :data_imports, :non_identifiable_records, :integer, default: 0, null: false
  end
end
