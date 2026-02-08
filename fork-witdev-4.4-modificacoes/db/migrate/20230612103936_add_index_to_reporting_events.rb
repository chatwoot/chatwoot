class AddIndexToReportingEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :reporting_events, [:account_id, :name, :created_at], name: 'reporting_events__account_id__name__created_at', algorithm: :concurrently
  end
end
