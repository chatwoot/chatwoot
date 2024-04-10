class CreateDataImports < ActiveRecord::Migration[6.0]
  def change
    create_table :data_imports do |t|
      t.references :account, null: false, foreign_key: true
      t.string :data_type, null: false
      t.integer :status, null: false, default: 0
      t.text :processing_errors
      t.integer :total_records
      t.integer :processed_records

      t.timestamps
    end
  end
end
