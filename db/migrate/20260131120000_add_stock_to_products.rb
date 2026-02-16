class AddStockToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :stock, :integer, null: true, default: nil
  end
end
