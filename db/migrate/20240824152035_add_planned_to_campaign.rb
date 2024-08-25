class AddPlannedToCampaign < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :planned, :boolean, null: false, default: false
  end
end
