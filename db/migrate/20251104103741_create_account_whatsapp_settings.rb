class CreateAccountWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :account_whatsapp_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :app_id
      t.string :app_secret
      t.string :configuration_id
      t.string :verify_token
      t.string :api_version, default: 'v22.0'

      t.timestamps
    end
  end
end
