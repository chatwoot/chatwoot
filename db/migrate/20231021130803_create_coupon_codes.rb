class CreateCouponCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :coupon_codes do |t|
      t.integer :account_id
      t.string :account_name
      t.string :code, unique: true
      t.string :partner
      t.string :status, default: 'new'
      t.datetime :redeemed_at
      t.datetime :expiry_date

      t.timestamps
    end
  end
end
