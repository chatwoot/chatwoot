class CreateInfluencerOffers < ActiveRecord::Migration[7.0]
  def change
    create_table :influencer_offers do |t|
      t.references :influencer_profile, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }

      t.string :token, null: false
      t.integer :status, default: 0, null: false

      t.jsonb :available_packages, default: {}
      t.jsonb :selected_packages, default: {}
      t.string :rights_level, default: 'standard'

      t.decimal :voucher_value, precision: 10, scale: 2
      t.string :voucher_currency, default: 'EUR'
      t.string :voucher_code

      t.text :custom_message
      t.datetime :terms_accepted_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :influencer_offers, :token, unique: true
  end
end
