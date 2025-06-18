class AddColumnPaymentExpiredToTransaction < ActiveRecord::Migration[7.0]
  def change
    add_column :transactions, :payment_expiry_date, :timestamp
  end
end
