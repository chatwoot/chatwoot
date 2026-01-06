class CreateAccountTapSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :account_tap_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :secret_key
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end
  end
end
