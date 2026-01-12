# frozen_string_literal: true

class CreateCampaignMessageMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :campaign_message_mappings do |t|
      t.references :campaign_delivery_report, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :whatsapp_message_id, null: false
      t.string :status, default: 'sent', null: false # sent, delivered, read, failed
      t.string :error_code
      t.string :error_message
      t.text :error_details

      t.timestamps
    end

    add_index :campaign_message_mappings, :whatsapp_message_id, unique: true
    add_index :campaign_message_mappings, :status
  end
end
