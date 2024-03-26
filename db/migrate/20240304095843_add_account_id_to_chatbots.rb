class AddAccountIdToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :account_id, :integer, null: false, default: 0
  end
end
