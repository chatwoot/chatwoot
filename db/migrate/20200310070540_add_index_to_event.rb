class AddIndexToEvent < ActiveRecord::Migration[6.0]
  def change
    add_index :events, :name
    add_index :events, :created_at
    add_index :events, :account_id
    add_index :events, :inbox_id
    add_index :events, :user_id
  end
end
