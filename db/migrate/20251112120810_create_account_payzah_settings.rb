class CreateAccountPayzahSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :account_payzah_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :api_key
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end
  end
end
