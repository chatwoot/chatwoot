class AddCustomerIdToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :customer_id, :string
  end
end
