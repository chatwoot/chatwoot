class AddQueueToConversations < ActiveRecord::Migration[7.0]
  def change
    add_reference :conversations, :queue, null: true, foreign_key: true
    add_index :conversations, :queue_id
  end
end