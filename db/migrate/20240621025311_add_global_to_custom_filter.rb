class AddGlobalToCustomFilter < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_filters, :account_scoped, :boolean, null: false, default: false
  end
end
