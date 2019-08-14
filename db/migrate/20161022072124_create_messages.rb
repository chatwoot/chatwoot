class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.text :content
      t.integer :account_id
      t.integer :channel_id
      t.integer :inbox_id
      t.integer :conversation_id
      t.integer :type
      t.timestamps
    end
  end
end
