class CreateCampaignContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_contacts do |t|
      t.references :campaign, null: false, foreign_key: true, index: true
      t.references :contact, null: false, foreign_key: true, index: true
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.datetime :sent_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :campaign_contacts, [:campaign_id, :contact_id], unique: true
    add_index :campaign_contacts, :status
  end
end
