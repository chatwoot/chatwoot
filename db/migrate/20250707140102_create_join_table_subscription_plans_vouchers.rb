class CreateJoinTableSubscriptionPlansVouchers < ActiveRecord::Migration[7.0]
  def change
    create_join_table :subscription_plans, :vouchers do |t|
      t.index [:subscription_plan_id, :voucher_id], name: 'index_plan_voucher'
    end
  end
end