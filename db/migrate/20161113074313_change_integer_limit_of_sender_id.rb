class ChangeIntegerLimitOfSenderId < ActiveRecord::Migration[5.0]
  def change
    change_column :conversations, :sender_id, :integer, limit: 8
  end
end
