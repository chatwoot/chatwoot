class RemoveQuestionFromAlooEmbeddings < ActiveRecord::Migration[7.1]
  def change
    remove_column :aloo_embeddings, :question, :text
  end
end
