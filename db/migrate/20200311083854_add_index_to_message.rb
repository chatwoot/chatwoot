class AddIndexToMessage < ActiveRecord::Migration[6.0]
  def change
    add_index :messages, :account_id
    add_index :messages, :inbox_id
    add_index :messages, :user_id
  end
end
