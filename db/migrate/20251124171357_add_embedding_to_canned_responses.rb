class AddEmbeddingToCannedResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :canned_responses, :embedding, :vector, limit: 1536
    add_index :canned_responses, :embedding, using: :ivfflat, opclass: :vector_l2_ops
  end
end
