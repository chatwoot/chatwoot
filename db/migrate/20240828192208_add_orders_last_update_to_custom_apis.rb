class AddOrdersLastUpdateToCustomApis < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_apis, :orders_last_update, :datetime
  end
end
