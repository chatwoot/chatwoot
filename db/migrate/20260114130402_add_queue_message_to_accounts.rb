class AddQueueMessageToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :queue_message, :text
  end
end
