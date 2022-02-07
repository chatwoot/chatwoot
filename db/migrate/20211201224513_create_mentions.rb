class CreateMentions < ActiveRecord::Migration[6.1]
  def change
    create_table :mentions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :account, index: true, null: false
      t.datetime :mentioned_at, null: false
      t.timestamps
    end

    add_index :mentions, [:user_id, :conversation_id], unique: true
  end
end
