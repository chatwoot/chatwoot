class CreateParquetReports < ActiveRecord::Migration[7.0]
  def change
    create_table :parquet_reports do |t|
      t.jsonb :params
      t.string :file_name
      t.string :file_url
      t.string :status
      t.integer :progress, default: 0
      t.string :error_message
      t.string :type
      t.references :account, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.timestamps
    end
  end
end
