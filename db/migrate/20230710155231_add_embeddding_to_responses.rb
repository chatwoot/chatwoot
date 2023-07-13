class AddEmbedddingToResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :responses, :embedding, :vector, limit: 1536
    add_index :responses, :embedding, using: :ivfflat, opclass: :vector_l2_ops
  end
end
