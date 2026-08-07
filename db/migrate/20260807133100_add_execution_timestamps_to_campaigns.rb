class AddExecutionTimestampsToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :started_at, :datetime
    add_column :campaigns, :completed_at, :datetime
  end
end
