# CommMate: Add available_for_campaigns flag to labels for campaign preferences
class AddAvailableForCampaignsToLabels < ActiveRecord::Migration[7.0]
  def change
    add_column :labels, :available_for_campaigns, :boolean, default: false
  end
end

