class AddAccountIdCreatedAtIndexToReportingEvents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :reporting_events, [:account_id, :created_at], algorithm: :concurrently
  end
end
