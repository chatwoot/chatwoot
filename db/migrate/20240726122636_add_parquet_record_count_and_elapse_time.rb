class AddParquetRecordCountAndElapseTime < ActiveRecord::Migration[7.0]
  def change
    add_column :parquet_reports, :record_count, :integer, default: 0
    add_column :parquet_reports, :elapse_time, :integer, default: 0
  end
end
