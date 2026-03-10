class CreatePaymentPresets < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_presets do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :amount_cents, null: false
      t.string :description, null: false
      t.timestamps
    end
  end
end
