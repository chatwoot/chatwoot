class AddCampaignTypeToCampaigns < ActiveRecord::Migration[6.0]
  def change
    change_table :campaigns, bulk: true do |t|
      t.integer :campaign_type, default: 0, null: false, index: true
      t.integer :campaign_status, default: 0, null: false, index: true
      t.jsonb :audience, default: []
      t.datetime :scheduled_at, index: true
    end
  end
end
