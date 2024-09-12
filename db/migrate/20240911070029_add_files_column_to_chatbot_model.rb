class AddFilesColumnToChatbotModel < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :text, :string
    add_column :chatbots, :urls, :jsonb, default: []
    add_column :conversations, :chatbot_status, :string, default: 'Enabled'
  end
end
