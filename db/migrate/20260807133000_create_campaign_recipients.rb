class CreateCampaignRecipients < ActiveRecord::Migration[7.1]
  def change
    create_campaign_recipients
    add_campaign_recipient_indexes
    add_column :campaigns, :started_at, :datetime
    add_column :campaigns, :completed_at, :datetime
  end

  private

  def create_campaign_recipients
    create_table :campaign_recipients do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :campaign, null: false, foreign_key: { on_delete: :cascade }
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }
      t.string :source_id
      t.integer :status, null: false, default: 0
      t.string :error_code
      t.string :error_title
      t.text :error_message
      t.text :message_content
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :read_at
      t.datetime :failed_at

      t.timestamps
    end
  end

  def add_campaign_recipient_indexes
    add_index :campaign_recipients, [:account_id, :campaign_id]
    add_index :campaign_recipients, [:campaign_id, :status]
    add_index :campaign_recipients, [:campaign_id, :contact_id], unique: true
    add_index :campaign_recipients, :source_id, unique: true, where: 'source_id IS NOT NULL'
  end
end
