class AddLockedAtInUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users, bulk: true do |t|
      t.datetime :locked_at
      t.integer :failed_attempts
      t.string :unlock_token
    end
  end
end
