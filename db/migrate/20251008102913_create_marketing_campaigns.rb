# frozen_string_literal: true

class CreateMarketingCampaigns < ActiveRecord::Migration[7.1] # :nodoc:
  def change
    create_table :marketing_campaigns do |t|
      t.string :title, null: false, default: ''
      t.text :description, default: ''
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :active, null: false, default: true
      t.string :source_id, default: ''
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
