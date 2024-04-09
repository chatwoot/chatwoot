class CreateChatbots < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbots do |t|
      t.integer :account_id, null: false, default: 0
      t.string :chatbot_id, null: false
      t.datetime :last_trained_at
      t.string :chatbot_name
      t.timestamps
    end
  end
end
