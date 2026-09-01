class AddCustomTitleToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :account_users, :custom_title, :string, default: nil
  end
end
