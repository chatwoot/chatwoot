class CreateMetaCampaignInteractions < ActiveRecord::Migration[7.1]
  def change
    create_table :meta_campaign_interactions do |t|
      t.references :inbox, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true
      t.string :source_id, null: false
      t.string :source_type
      t.string :ctwa_clid
      t.jsonb :metadata, default: {}
      t.string :interaction_type, default: 'initial_message'

      t.timestamps
    end

    add_index :meta_campaign_interactions, [:inbox_id, :source_id]
    add_index :meta_campaign_interactions, [:account_id, :source_id]
    add_index :meta_campaign_interactions, :source_id
    add_index :meta_campaign_interactions, :created_at
  end
end
