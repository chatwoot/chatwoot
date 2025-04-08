class AddColumnsToPricingPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :pricing_plans, :monthly_price, :integer, default: 0
    add_column :pricing_plans, :annual_price, :integer, default: 0
    add_column :pricing_plans, :integration_channels, :text
    add_column :pricing_plans, :support_level, :string
    add_column :pricing_plans, :sequence_number, :integer
  end
end
