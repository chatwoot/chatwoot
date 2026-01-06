class CreateAccountCatalogSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :account_catalog_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, default: false, null: false
      t.string :payment_provider
      t.string :currency, default: 'SAR'

      t.timestamps
    end
  end
end
