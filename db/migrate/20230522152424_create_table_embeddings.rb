class CreateTableEmbeddings < ActiveRecord::Migration[7.0]
  def change
    create_table :embeddings do |t|
      t.references :account, index: true, null: false
      t.references :obj, polymorphic: true, null: false
      t.vector :embedding, limit: 1536
      t.index :embedding, using: :ivfflat, opclass: :vector_l2_ops
      t.timestamps
    end
  end
end
