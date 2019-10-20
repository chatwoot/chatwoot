class Notnullableusers < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :name, :string, null: false
    change_column :users, :account_id, :integer, null: false
  end
end
