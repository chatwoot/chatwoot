class AddBillingCyclesToSubscriptionPlansVouchers < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_plans_vouchers, :applicable_billing_cycles, :text, 
               array: true, default: ['monthly', 'quarterly', 'halfyear', 'yearly']
    
    add_column :subscription_plans_vouchers, :id, :primary_key
  end
end
