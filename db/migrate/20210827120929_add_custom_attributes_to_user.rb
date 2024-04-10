class AddCustomAttributesToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :custom_attributes, :jsonb, default: {}
  end
end
