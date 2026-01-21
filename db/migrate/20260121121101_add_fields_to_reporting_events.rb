class AddFieldsToReportingEvents < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :reporting_events, :conversation_created_at, :datetime
    add_column :reporting_events, :from_state, :string
    add_column :reporting_events, :team_id, :bigint
    add_column :reporting_events, :channel_type, :string

    add_index :reporting_events, [:account_id, :conversation_created_at, :name],
              algorithm: :concurrently, name: 'idx_reporting_events_on_account_conv_created_at_name'
    add_index :reporting_events, [:account_id, :from_state, :name, :created_at],
              algorithm: :concurrently, name: 'idx_reporting_events_on_account_from_state_name_created'
    add_index :reporting_events, [:account_id, :team_id, :name, :created_at],
              algorithm: :concurrently, name: 'idx_reporting_events_on_account_team_name_created'
    add_index :reporting_events, [:account_id, :channel_type, :name, :created_at],
              algorithm: :concurrently, name: 'idx_reporting_events_on_account_channel_name_created'
  end
end
