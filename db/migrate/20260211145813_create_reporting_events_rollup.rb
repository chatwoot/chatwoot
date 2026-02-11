class CreateReportingEventsRollup < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    create_table :reporting_events_rollups do |t|
      t.integer :account_id, null: false
      t.date :date, null: false
      t.string :dimension_type, null: false
      t.bigint :dimension_id, null: false
      t.string :metric, null: false
      t.bigint :count, default: 0, null: false
      t.float :sum_value, default: 0.0, null: false
      t.float :sum_value_business_hours, default: 0.0, null: false

      t.timestamps
    end

    # Unique index for upsert conflict resolution
    add_index :reporting_events_rollups,
              [:account_id, :date, :dimension_type, :dimension_id, :metric],
              unique: true,
              name: 'index_rollup_unique_key'

    # Query index for timeseries (date range scans)
    add_index :reporting_events_rollups,
              [:account_id, :metric, :date],
              name: 'index_rollup_timeseries'

    # Query index for summaries (dimension scans)
    add_index :reporting_events_rollups,
              [:account_id, :dimension_type, :date],
              name: 'index_rollup_summary'
  end
end
