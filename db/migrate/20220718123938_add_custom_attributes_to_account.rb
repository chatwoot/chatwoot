class AddCustomAttributesToAccount < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :custom_attributes, :jsonb, default: {}
  end
end
