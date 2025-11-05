class AddAllowBotsToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :allow_bots, :boolean, default: false, null: false
  end
end
