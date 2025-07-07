class CreateVoucherUsages < ActiveRecord::Migration[7.0]
  def change
    create_table :voucher_usages do |t|
      t.references :voucher, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :subscription, foreign_key: true

      t.timestamps
    end
  end
end