class AddAccountIdAndUserIdToCustomApis < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_apis, :account_id, :integer
    add_column :custom_apis, :user_id, :integer
  end
end
