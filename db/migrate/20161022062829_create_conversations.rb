class CreateConversations < ActiveRecord::Migration[5.0]
  def change
    create_table :conversations do |t|
      t.integer :account_id
      t.integer :channel_id
      t.integer :inbox_id
      t.integer :status
      t.integer :assignee_id

      t.timestamps
    end
  end
end
