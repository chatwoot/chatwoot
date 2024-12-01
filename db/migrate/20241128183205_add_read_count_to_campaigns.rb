class AddReadCountToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :read_count, :integer, default: 0
  end
end
