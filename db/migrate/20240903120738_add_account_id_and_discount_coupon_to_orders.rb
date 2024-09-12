class AddAccountIdAndDiscountCouponToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :account_id, :integer
    add_column :orders, :discount_coupon, :string
  end
end
