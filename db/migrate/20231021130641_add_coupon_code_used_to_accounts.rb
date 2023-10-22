class AddCouponCodeUsedToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :coupon_code_used, :integer, default: 0
  end
end
