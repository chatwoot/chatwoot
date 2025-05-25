class CreateFacebookAdsTracking < ActiveRecord::Migration[7.0]
  def change
    create_table :facebook_ads_trackings do |t|
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :message, null: true, foreign_key: true, index: true
      t.references :contact, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true

      # Facebook referral data
      t.string :ref_parameter, index: true
      t.string :referral_source
      t.string :referral_type
      t.string :ad_id, index: true
      t.string :campaign_id, index: true
      t.string :adset_id, index: true

      # Ads context data
      t.string :ad_title
      t.string :ad_photo_url
      t.string :ad_video_url

      # Raw referral data for debugging
      t.json :raw_referral_data

      # Conversion tracking
      t.boolean :conversion_sent, default: false, index: true
      t.datetime :conversion_sent_at
      t.json :conversion_response

      # Event tracking
      t.string :event_name
      t.decimal :event_value, precision: 10, scale: 2
      t.string :currency, default: 'USD'

      # Additional attributes for custom events and metadata
      t.json :additional_attributes

      t.timestamps
    end

    add_index :facebook_ads_trackings, [:account_id, :created_at]
    add_index :facebook_ads_trackings, [:ad_id, :created_at]
    add_index :facebook_ads_trackings, [:ref_parameter, :created_at]
  end
end
