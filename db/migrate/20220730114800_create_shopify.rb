class CreateShopify < ActiveRecord::Migration[6.0]
    def change
      create_table :integrations_shopify, id: :serial do |t|
        t.integer :account_id
        t.string  :account_name
        t.string  :api_key
        t.string  :api_secret
        t.string  :access_token
        t.string  :redirect_url
        t.timestamps
      end
    end
  end
