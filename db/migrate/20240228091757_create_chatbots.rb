class CreateChatbots < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbots do |t|
      t.string :chatbot_id, null: false # chatbotID (cannot be changed)
      t.datetime :last_trained_at # last trained at (may change)
      t.string :chatbot_name # chatbot name (can be changed)
      t.timestamps
    end
  end
end
