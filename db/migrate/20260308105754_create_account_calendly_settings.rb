class CreateAccountCalendlySettings < ActiveRecord::Migration[7.1]
  def change
    create_table :account_calendly_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :access_token
      t.string :user_uri
      t.string :organization_uri
      t.string :scheduling_url
      t.boolean :enabled, default: false, null: false
      t.string :webhook_signing_key
      t.string :webhook_subscription_uri

      t.timestamps
    end
  end
end
