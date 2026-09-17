class CreateCampaignBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_batches do |t|
      t.references :campaign, null: false, foreign_key: true
      t.jsonb :contact_ids, null: false
      t.datetime :processed_at
      t.timestamps
    end
  end
end
