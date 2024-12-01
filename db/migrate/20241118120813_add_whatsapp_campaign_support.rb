class AddWhatsappCampaignSupport < ActiveRecord::Migration[7.0]
  def change
    # Add template_id to campaigns
    add_column :campaigns, :template_id, :bigint
    add_index :campaigns, :template_id

    # Create join table for campaigns and contacts
    create_table :campaigns_contacts do |t|
      t.bigint :campaign_id, null: false
      t.bigint :contact_id, null: false
      t.string :status, default: 'pending' # Track message delivery status
      t.datetime :processed_at
      t.text :error_message
      t.timestamps
    end

    add_index :campaigns_contacts, [:campaign_id, :contact_id], unique: true
    add_foreign_key :campaigns_contacts, :campaigns, on_delete: :cascade
    add_foreign_key :campaigns_contacts, :contacts, on_delete: :cascade

    # Add status tracking columns to campaigns
    add_column :campaigns, :processed_contacts_count, :integer, default: 0
    add_column :campaigns, :failed_contacts_count, :integer, default: 0
  end
end
