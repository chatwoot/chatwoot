class RenameCampaignContentToMessage < ActiveRecord::Migration[6.0]
  def change
    rename_column :campaigns, :content, :message
  end
end
