# Upstream campaign analytics columns. Table may already exist from PaluHub
# CreateCampaignRecipientsAndExecutionStats (20260718000000).
class CreateCampaignRecipients < ActiveRecord::Migration[7.1]
  def change
    if table_exists?(:campaign_recipients)
      upgrade_existing_campaign_recipients
    else
      create_campaign_recipients
      add_campaign_recipient_indexes
    end

    add_column :campaigns, :started_at, :datetime unless column_exists?(:campaigns, :started_at)
    add_column :campaigns, :completed_at, :datetime unless column_exists?(:campaigns, :completed_at)
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

  def upgrade_existing_campaign_recipients
    unless column_exists?(:campaign_recipients, :inbox_id)
      add_reference :campaign_recipients, :inbox, foreign_key: { on_delete: :cascade }
    end
    add_column :campaign_recipients, :error_code, :string unless column_exists?(:campaign_recipients, :error_code)
    add_column :campaign_recipients, :error_title, :string unless column_exists?(:campaign_recipients, :error_title)
    add_column :campaign_recipients, :message_content, :text unless column_exists?(:campaign_recipients, :message_content)

    add_index :campaign_recipients, [:account_id, :campaign_id] unless index_exists?(:campaign_recipients, [:account_id, :campaign_id])
    unless index_exists?(:campaign_recipients, [:campaign_id, :contact_id], unique: true)
      remove_index :campaign_recipients, [:campaign_id, :contact_id] if index_exists?(:campaign_recipients, [:campaign_id, :contact_id])
      add_index :campaign_recipients, [:campaign_id, :contact_id], unique: true
    end
  end

  def add_campaign_recipient_indexes
    add_index :campaign_recipients, [:account_id, :campaign_id]
    add_index :campaign_recipients, [:campaign_id, :status]
    add_index :campaign_recipients, [:campaign_id, :contact_id], unique: true
    add_index :campaign_recipients, :source_id, unique: true, where: 'source_id IS NOT NULL'
  end
end
