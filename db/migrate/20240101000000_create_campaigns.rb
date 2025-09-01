class CreateCampaigns < ActiveRecord::Migration[6.1]
  def change
    create_table :campaigns do |t|
      t.string :name, null: false
      t.text :description
      t.integer :campaign_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :target_segments, default: {}
      t.jsonb :message_templates, default: {}
      t.datetime :scheduled_at
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :campaigns, [:account_id, :status]
    add_index :campaigns, :campaign_type
  end
end
