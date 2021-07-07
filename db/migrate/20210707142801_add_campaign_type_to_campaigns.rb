class AddCampaignTypeToCampaigns < ActiveRecord::Migration[6.0]
  def change
    change_table :campaigns, bulk: true do |t|
      t.integer :campaign_type, default: 0, null: false
      t.boolean :locked, default: false, null: false
      t.jsonb :audience, default: []
      t.datetime :trigger_time
    end
  end
end
