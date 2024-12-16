class AddTrackingCodeToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :tracking_code, :string
  end
end
