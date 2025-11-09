class AddQueueEnabledToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :queue_enabled, :boolean, default: false, null: false
  end
end
