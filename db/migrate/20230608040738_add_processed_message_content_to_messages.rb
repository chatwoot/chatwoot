class AddProcessedMessageContentToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :processed_message_content, :text, null: true
  end
end
