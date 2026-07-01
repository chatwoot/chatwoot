class AddAutoQaToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :auto_qa_score, :float
    add_column :conversations, :auto_qa_feedback, :text
    add_index :conversations, :auto_qa_score
  end
end
