class CreateShopeeVouchers < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_vouchers do |t|
      t.timestamps
      t.bigint :shop_id, null: false
      t.bigint :voucher_id, null: false
      t.string :code, null: false
      t.string :name, null: false
      t.datetime :start_time
      t.datetime :end_time
      t.jsonb :meta, default: {}
    end

    add_index :shopee_vouchers, :shop_id
    add_index :shopee_vouchers, :voucher_id, unique: true
    add_index :shopee_vouchers, :code, unique: true
  end
end
