class CreateAccountPaymentLinkSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :account_payment_link_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :default_provider
      t.string :default_currency, default: 'KWD'
      t.string :notification_email

      t.timestamps
    end
  end
end
