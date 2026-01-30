class AddIndexToReportingEventsForResponseDistribution < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :reporting_events,
              [:account_id, :name, :inbox_id, :created_at],
              name: 'index_reporting_events_for_response_distribution',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
