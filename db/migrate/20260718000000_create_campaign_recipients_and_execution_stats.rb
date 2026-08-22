class CreateCampaignRecipientsAndExecutionStats < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :execution_stats, :jsonb, default: {}, null: false

    create_table :campaign_recipients do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :phone_number
      t.integer :status, null: false, default: 0
      t.string :source_id
      t.text :error_message
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :read_at
      t.datetime :failed_at

      t.timestamps
    end

    add_index :campaign_recipients, [:campaign_id, :status]
    add_index :campaign_recipients, [:campaign_id, :contact_id]
    add_index :campaign_recipients, :source_id, unique: true, where: 'source_id IS NOT NULL'
  end
end
