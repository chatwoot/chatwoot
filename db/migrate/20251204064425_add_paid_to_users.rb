class AddPaidToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :paid, :boolean, default: false
  end
end
