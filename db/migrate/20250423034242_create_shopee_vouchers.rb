class CreateShopeeVouchers < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_vouchers do |t|
      t.timestamps
      t.string :code, null: false
      t.string :name, null: false
      t.integer :usage_quantity
      t.integer :current_usage
      t.datetime :start_time
      t.datetime :end_time
      t.string :voucher_purpose
      t.integer :percentage
      t.integer :max_price
      t.integer :min_basket_price
      t.integer :discount_amount
      t.string :target_voucher
      t.string :usecase
    end

    add_index :shopee_vouchers, :code, unique: true
  end
end
