# frozen_string_literal: true

class CreateCampaignDeliveryReports < ActiveRecord::Migration[7.0]
  def change
    create_table :campaign_delivery_reports do |t|
      t.references :campaign, null: false, foreign_key: true, index: { unique: true }
      t.string :provider
      t.string :status, default: 'pending', null: false
      t.integer :total, default: 0, null: false
      t.integer :succeeded, default: 0, null: false
      t.integer :failed, default: 0, null: false
      t.jsonb :errors, default: [], null: false
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :campaign_delivery_reports, :status
  end
end
